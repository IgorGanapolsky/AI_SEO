#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "fileutils"
require "json"
require "time"

ROOT = File.expand_path("..", __dir__)
BASE_URL = ENV.fetch("BASE_URL", "http://localhost:4174")
OUT_DIR = File.join(ROOT, "reports", "gtm", "2026-05-06-money-today")
OUT_PATH = File.join(OUT_DIR, "zernio-queue.json")

FileUtils.mkdir_p(OUT_DIR)

posts = CSV.read(File.join(ROOT, "data", "social_posts.csv"), headers: true).map.with_index(1) do |row, index|
  text = row.fetch("post").gsub("./site", BASE_URL)
  {
    id: "ai-seo-#{Time.now.strftime("%Y%m%d")}-#{index}",
    channel: row.fetch("channel"),
    theme: row.fetch("theme"),
    text: text,
    status: "ready",
    created_at: Time.now.iso8601
  }
end

File.write(OUT_PATH, JSON.pretty_generate(posts))
puts "Wrote #{posts.length} queued posts to #{OUT_PATH}"
