#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "open3"
require "set"
require "time"
require "timeout"

ROOT = File.expand_path("..", __dir__)
LEADS_PATH = File.join(ROOT, "sales", "lead_tracker.csv")
SENT_LOCK_PATH = File.join(ROOT, "sales", "sent_lock.csv")
LOG_DIR = File.join(ROOT, "reports", "gtm", "2026-05-06-money-today")
LIMIT = Integer(ENV.fetch("LIMIT", "5"))
DRY_RUN = ENV["CONFIRM_SEND"] != "YES"

FileUtils.mkdir_p(LOG_DIR)

def read_csv(path)
  CSV.parse(File.read(path, encoding: "UTF-8"), headers: true)
end

def write_csv(path, rows)
  CSV.open(path, "w", write_headers: true, headers: rows.headers) do |csv|
    rows.each { |row| csv << row }
  end
end

def applescript_string(value)
  value.to_s.gsub("\\", "\\\\\\").gsub('"', '\\"')
end

def applescript_multiline(value)
  value.to_s.split("\n", -1).map { |line| "\"#{applescript_string(line)}\"" }.join(" & return & ")
end

def email_body(row)
  [
    "Hey #{row["business_name"]} team,",
    "",
    "I saw your public n8n/AI automation work and built a narrow $49 teardown for one broken workflow: n8n automation, restaurant call flow, lead handoff, or agent workflow.",
    "",
    "It returns 3 concrete fixes and the next action. If useful, it can sit before a larger $499 diagnostic or be used as a partner/referral offer for clients who are not ready for a full build yet.",
    "",
    "Offer page:",
    "https://ai-seo-operator-stack.web.app/offers/ai-workflow-quick-teardown.html",
    "",
    "Checkout:",
    "https://buy.stripe.com/6oU00jduQ3n03hDfSH3sI16",
    "",
    "Worth trying on one messy workflow?",
    "",
    "Igor Ganapolsky",
    "AI Operator Stack",
    "201 639 1534",
    "",
    "--",
    "Ad/solicitation disclosure: I am reaching out about a paid workflow diagnostic.",
    "Opt out: reply \"no\" and I will not contact you again.",
    "Mailing address: 11909 Glenmore Dr, Coral Springs, FL 33071"
  ].join("\n")
end

def build_applescript(row)
  <<~APPLESCRIPT
    on run argv
      set emailAddress to "#{applescript_string(row["email"])}"
      set subjectLine to "Quick n8n workflow teardown idea"
      set bodyText to #{applescript_multiline(email_body(row))}
      with timeout of 180 seconds
        tell application "Mail"
          set newMessage to make new outgoing message with properties {subject:subjectLine, content:bodyText, visible:false}
          tell newMessage
            make new to recipient at end of to recipients with properties {address:emailAddress}
            send
          end tell
        end tell
      end timeout
      return "#{applescript_string(row["business_name"])}" & "," & emailAddress
    end run
  APPLESCRIPT
end

rows = read_csv(LEADS_PATH)
sent_lock = read_csv(SENT_LOCK_PATH).map { |row| row["email"].to_s.downcase }.to_set
eligible = rows.select do |row|
  row["status"] == "draft" &&
    row["email"].to_s.include?("@") &&
    !sent_lock.include?(row["email"].to_s.downcase)
end.first(LIMIT)

timestamp = Time.now.iso8601
safe_stamp = timestamp.gsub(/[:+]/, "-")
log_path = File.join(LOG_DIR, "agency-outreach-#{safe_stamp}.csv")
sent = []
log_rows = []

eligible.each_with_index do |row, index|
  if DRY_RUN
    log_rows << [row["business_name"], row["email"], "dry_run", "", timestamp]
    next
  end

  script_path = File.join(LOG_DIR, "agency-mail-#{safe_stamp}-#{index + 1}.applescript")
  File.write(script_path, build_applescript(row))
  stdout = +""
  stderr = +""
  status = nil
  begin
    Timeout.timeout(240) do
      stdout, stderr, status = Open3.capture3("osascript", script_path)
    end
  rescue Timeout::Error
    log_rows << [row["business_name"], row["email"], "timeout", "osascript timed out", timestamp]
    next
  end

  if status&.success?
    sent << row["email"]
    log_rows << [row["business_name"], row["email"], "sent", stdout.strip, timestamp]
  else
    log_rows << [row["business_name"], row["email"], "error", "#{stderr} #{stdout}".strip, timestamp]
  end
  sleep 2
end

unless DRY_RUN
  rows.each do |row|
    next unless sent.include?(row["email"])

    row["status"] = "contacted"
    row["last_touch"] = timestamp
    row["next_step"] = "Watch for reply or $49 checkout"
  end
  write_csv(LEADS_PATH, rows)

  lock_rows = read_csv(SENT_LOCK_PATH)
  sent.each do |email|
    lock_rows << CSV::Row.new(lock_rows.headers, [email.downcase, timestamp, "1", "false"])
  end
  write_csv(SENT_LOCK_PATH, lock_rows)
end

CSV.open(log_path, "w", write_headers: true, headers: %w[business_name email status detail timestamp]) do |csv|
  log_rows.each { |row| csv << row }
end

puts "#{DRY_RUN ? "would send" : "sent"} #{DRY_RUN ? eligible.length : sent.length} emails"
puts log_path
