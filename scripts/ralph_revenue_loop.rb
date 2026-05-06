#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "open3"
require "time"

ROOT = File.expand_path("..", __dir__)
REPORT_DIR = File.join(ROOT, "reports", "gtm", "2026-05-06-money-today")
LOCK_PATH = File.join(REPORT_DIR, "ralph-loop.lock")
LATEST_REPORT = File.join(REPORT_DIR, "ralph-loop-latest.md")
SOCIAL_PATH = File.join(ROOT, "data", "social_posts.csv")

FileUtils.mkdir_p(REPORT_DIR)

def run_cmd(*args)
  stdout, stderr, status = Open3.capture3(*args, chdir: ROOT)
  { stdout: stdout, stderr: stderr, status: status.exitstatus, success: status.success? }
end

def csv_count(path)
  CSV.read(path, headers: true).length
end

def latest_social_posts(limit)
  CSV.read(SOCIAL_PATH, headers: true).first(limit).map do |row|
    "- #{row["channel"]} / #{row["theme"]}: #{row["post"]}"
  end
end

File.open(LOCK_PATH, File::RDWR | File::CREAT, 0o644) do |lock_file|
  unless lock_file.flock(File::LOCK_EX | File::LOCK_NB)
    warn "Ralph loop already running"
    exit 0
  end

  timestamp = Time.now.iso8601
  build = run_cmd("ruby", "scripts/build_site.rb")
  pages = Dir.glob(File.join(ROOT, "site", "**", "*.html")).length
  tools = csv_count(File.join(ROOT, "data", "tools.csv"))
  comparisons = csv_count(File.join(ROOT, "data", "comparisons.csv"))
  social_posts = latest_social_posts(6)

  report = [
    "# Ralph Revenue Loop Latest",
    "",
    "Generated: #{timestamp}",
    "",
    "## Build",
    "",
    "```text",
    build[:stdout].strip,
    build[:stderr].strip,
    "exit=#{build[:status]}",
    "```",
    "",
    "## Inventory",
    "",
    "- Static HTML pages: #{pages}",
    "- Tool records: #{tools}",
    "- Comparison records: #{comparisons}",
    "",
    "## Distribution Queue",
    "",
    social_posts,
    "",
    "## Revenue Truth",
    "",
    "- No affiliate dashboard or Stripe API verification was performed by this local script.",
    "- Treat this as content operation status, not payment truth.",
    "",
    "## Next Execution Block",
    "",
    "- Publish the top restaurant AI comparison through Zernio.",
    "- Apply for or confirm partner tracking links for n8n, RingFoods, Maple, ShevaFood, and FoodShot AI.",
    "- Replace public program URLs in `data/tools.csv` only after tracking URLs are issued."
  ].flatten.join("\n")

  File.write(LATEST_REPORT, "#{report}\n")
end
