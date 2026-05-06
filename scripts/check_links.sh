#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export ROOT

find "$ROOT/site" -name "*.html" -print0 |
  xargs -0 ruby -e '
    ARGV.each do |path|
      html = File.read(path)
      html.scan(/href="([^"]+)"/).flatten.each do |href|
        next if href.start_with?("http://", "https://", "mailto:", "#")
        target = if href.start_with?("/")
          File.join(ENV.fetch("ROOT"), "site", href.sub(%r{\A/}, ""))
        else
          File.expand_path(File.join(File.dirname(path), href))
        end
        unless File.exist?(target)
          warn "#{path}: missing #{href} -> #{target}"
          exit 1
        end
      end
    end
  '

echo "Local links ok"
