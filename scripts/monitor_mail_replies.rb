#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "open3"
require "time"

ROOT = File.expand_path("..", __dir__)
REPORT_DIR = File.join(ROOT, "reports", "gtm", "2026-05-06-money-today")
LEADS_PATH = File.join(ROOT, "sales", "lead_tracker.csv")
SENT_LOCK_PATH = File.join(ROOT, "sales", "sent_lock.csv")
REPORT_PATH = File.join(REPORT_DIR, "mail-monitor-latest.md")
RECENT_LIMIT = Integer(ENV.fetch("MAIL_LIMIT", "80"))

FileUtils.mkdir_p(REPORT_DIR)

def applescript(limit)
  <<~APPLESCRIPT
    set outputLines to {}
    tell application "Mail"
      set inboxMessages to messages of inbox
      repeat with i from 1 to (count of inboxMessages)
        if i > #{limit} then exit repeat
        try
          set m to item i of inboxMessages
          set bodyText to ""
          set senderText to sender of m
          set subjectText to subject of m
          if senderText contains "George" or senderText contains "george" or subjectText contains "QSR OpenClaw" or subjectText contains "workflow teardown" or subjectText contains "sent you a message" then
            set bodyText to content of m
          end if
          if length of bodyText > 1200 then set bodyText to text 1 thru 1200 of bodyText
          set end of outputLines to "INBOX" & tab & ((date received of m) as text) & tab & senderText & tab & subjectText & tab & bodyText
        end try
      end repeat

      set sentMessages to messages of sent mailbox
      repeat with i from 1 to (count of sentMessages)
        if i > #{limit} then exit repeat
        try
          set m to item i of sentMessages
          set recipientText to (address of every to recipient of m) as text
          set end of outputLines to "SENT" & tab & ((date sent of m) as text) & tab & recipientText & tab & (subject of m) & tab & ""
        end try
      end repeat
    end tell
    set AppleScript's text item delimiters to linefeed
    return outputLines as text
  APPLESCRIPT
end

def load_leads
  CSV.read(LEADS_PATH, headers: true).map do |row|
    {
      email: row["email"].to_s.downcase,
      business: row["business_name"].to_s,
      status: row["status"].to_s
    }
  end
end

def load_sent_locks
  CSV.read(SENT_LOCK_PATH, headers: true).each_with_object({}) do |row, memo|
    memo[row["email"].to_s.downcase] = {
      sent_count: row["sent_count"].to_i,
      duplicate: row["duplicate"].to_s == "true"
    }
  end
end

def classify(line, leads)
  box, date, party, subject, body = line.split("\t", 5)
  haystack = [party, subject, body].join(" ").downcase
  lead = leads.find { |candidate| candidate[:email] != "" && haystack.include?(candidate[:email]) }
  lead ||= leads.find { |candidate| candidate[:business] != "" && haystack.include?(candidate[:business].downcase) }
  return nil unless lead || haystack.include?("george") || haystack.include?("slushie kang")

  signal =
    if box == "INBOX" && haystack.match?(/email me|examples|subway|interested|yes|pricing|checkout|buy/)
      "warm_reply"
    elsif box == "INBOX" && haystack.match?(/unsubscribe|opt out|do not contact|\\bno\\b/)
      "opt_out_or_negative"
    elsif box == "SENT"
      "sent_message"
    else
      "mention"
    end

  {
    box: box,
    date: date,
    party: party,
    subject: subject,
    body: body.to_s.gsub(/\s+/, " ").strip[0, 360],
    lead: lead,
    signal: signal
  }
end

stdout, stderr, status = Open3.capture3("osascript", stdin_data: applescript(RECENT_LIMIT))
unless status.success?
  warn stderr
  exit status.exitstatus || 1
end

leads = load_leads
locks = load_sent_locks
events = stdout.lines.map { |line| classify(line.chomp, leads) }.compact
sent_counts = events.select { |event| event[:box] == "SENT" }.group_by { |event| event.dig(:lead, :email) || event[:party].downcase }
duplicates = sent_counts.select { |_key, grouped| grouped.length > 1 }

timestamp = Time.now.iso8601
report = [
  "# Mail Monitor Latest",
  "",
  "Generated: #{timestamp}",
  "",
  "## Warm Signals",
  ""
]

if events.empty?
  report << "- No matching warm replies or tracked lead mentions in the recent Inbox/Sent window."
else
  events.each do |event|
    lead_name = event.dig(:lead, :business) || "unmatched"
    report << "- #{event[:signal]} | #{event[:box]} | #{event[:date]} | #{lead_name} | #{event[:party]} | #{event[:subject]}"
    report << "  #{event[:body]}" unless event[:body].empty?
  end
end

report += [
  "",
  "## Duplicate Guard",
  ""
]

if duplicates.empty?
  report << "- No duplicate sent messages found in the recent tracked window."
else
  duplicates.each do |key, grouped|
    lock = locks[key]
    lock_text = lock ? "sent_lock=#{lock[:sent_count]}, duplicate=#{lock[:duplicate]}" : "sent_lock=missing"
    report << "- #{key}: #{grouped.length} sent messages in recent window; #{lock_text}. Do not send another follow-up until a new inbound reply arrives."
  end
end

locked = locks.select { |_email, lock| lock[:duplicate] || lock[:sent_count] > 1 }
unless locked.empty?
  report << ""
  report << "## Locked Leads"
  report << ""
  locked.each do |email, lock|
    lead = leads.find { |candidate| candidate[:email] == email }
    lead_name = lead ? lead[:business] : email
    report << "- #{lead_name} / #{email}: sent_count=#{lock[:sent_count]}, duplicate=#{lock[:duplicate]}. Do not send again until a new inbound reply or payment."
  end
end

report += [
  "",
  "## Next Action",
  "",
  "- George / Slushie Kang is warm inbound. Stop additional same-day email. Monitor for payment or a specific reply with menu/order-flow details.",
  "- If no response after 24 hours, send one short proof-safe follow-up with a public mockup, not another Subway claim."
]

File.write(REPORT_PATH, "#{report.join("\n")}\n")
puts REPORT_PATH
