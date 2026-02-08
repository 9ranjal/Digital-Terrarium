#!/usr/bin/env ruby
# Fetches cover URLs from Open Library for books in _data/books.yml that are missing a cover.
# Run from repo root: ruby scripts/fetch_book_covers.rb
# Set REFRESH=1 to refetch all covers (overwrite existing).

require "net/http"
require "json"
require "uri"

BOOKS_PATH = File.join(__dir__, "..", "_data", "books.yml")

def fetch_cover(title, author)
  params = URI.encode_www_form("title" => title, "author" => author)
  url = URI("https://openlibrary.org/search.json?#{params}")
  res = Net::HTTP.get_response(url)
  return nil unless res.is_a?(Net::HTTPSuccess)

  data = JSON.parse(res.body)
  doc = data["docs"]&.first
  return nil unless doc && doc["cover_i"]

  "https://covers.openlibrary.org/b/id/#{doc['cover_i']}-M.jpg"
end

content = File.read(BOOKS_PATH, encoding: "UTF-8")
refresh = ENV["REFRESH"] == "1"
updated = 0

# Parse blocks: each book starts with "- title:"
blocks = content.split(/\n(?=- title:)/)
new_blocks = blocks.map do |block|
  next block unless block.strip.start_with?("- title:")

  has_cover = block.include?("cover:")
  skip = has_cover && !refresh
  if skip
    block
  else
    title = block[/title:\s*["']?(.+?)["']?\s*$/m] && $1&.strip
    author = block[/author:\s*["']?(.+?)["']?\s*$/m] && $1&.strip
    title = title.to_s.gsub(/^["']|["']\s*$/, "")
    author = author.to_s.gsub(/^["']|["']\s*$/, "")

    if title.empty? || author.empty?
      block
    else
      cover = fetch_cover(title, author)
      if cover
        updated += 1
        puts "  ✓ #{title}"
      else
        puts "  ✗ #{title} (no cover found)"
      end

      if cover
        # Remove existing cover line if refreshing
        block = block.lines.reject { |l| l.strip.start_with?("cover:") }.join
        # Insert cover after the first key-value (title); find a good insertion point (after author line)
        if block =~ /(author:\s*.+?\n)/
          block.sub($1, "#{$1}  cover: \"#{cover}\"\n")
        else
          block
        end
      else
        block
      end
    end
  end
end

# First "block" might be leading comments before the first "- title:"
out = new_blocks.join("\n\n")
File.write(BOOKS_PATH, out, encoding: "UTF-8")
puts "\nUpdated #{updated} cover(s) in _data/books.yml"
