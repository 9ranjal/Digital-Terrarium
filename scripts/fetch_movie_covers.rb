#!/usr/bin/env ruby
# frozen_string_literal: true

# Fetch movie poster URLs from TMDB and write them into _data/movies.yml.
#
# Usage:
#   TMDB_API_KEY=your_key ruby scripts/fetch_movie_covers.rb
#   REFRESH=1 TMDB_API_KEY=your_key ruby scripts/fetch_movie_covers.rb   # refetch all
#
# Requires a free API key from https://www.themoviedb.org/settings/api

require "net/http"
require "uri"
require "json"

MOVIES_PATH = File.expand_path("../_data/movies.yml", __dir__)
API_KEY     = ENV["TMDB_API_KEY"] || "5f2b19b28c5626c2b197ea35612aed1a"
REFRESH     = ENV["REFRESH"] == "1"
BASE_IMG    = "https://image.tmdb.org/t/p/w500"

abort "Missing TMDB_API_KEY env var and no default key" if API_KEY.to_s.empty?

def fetch_poster(title, year = nil)
  params = { "api_key" => API_KEY, "query" => title }
  params["year"] = year.to_s if year
  uri = URI("https://api.themoviedb.org/3/search/movie?#{URI.encode_www_form(params)}")
  res = Net::HTTP.get_response(uri)
  return nil unless res.is_a?(Net::HTTPSuccess)

  data = JSON.parse(res.body)
  poster = data.dig("results", 0, "poster_path")
  poster ? "#{BASE_IMG}#{poster}" : nil
rescue StandardError => e
  warn "  ⚠ #{title}: #{e.message}"
  nil
end

content = File.read(MOVIES_PATH, encoding: "UTF-8")
blocks  = content.split(/^(?=- title:)/)

new_blocks = blocks.map do |block|
  next block unless block.start_with?("- title:")

  title = block[/title:\s*"(.+?)"/, 1]
  year  = block[/year:\s*(\d+)/, 1]
  has_cover = block =~ /cover:\s*"[^"]+"/

  if has_cover && !REFRESH
    puts "✓ #{title} (already has cover)"
    next block
  end

  puts "⟳ #{title} …"
  url = fetch_poster(title, year)

  if url
    puts "  → #{url}"
    if block =~ /^(\s*cover:\s*).*$/
      block.sub!(/^(\s*cover:\s*).*$/, "\\1\"#{url}\"")
    else
      block.sub!(/^(  year_group:.*)$/, "  cover: \"#{url}\"\n\\1")
    end
  else
    puts "  ✗ not found"
  end

  block
end

File.write(MOVIES_PATH, new_blocks.join("\n\n"), encoding: "UTF-8")
puts "\nDone — #{MOVIES_PATH} updated."
