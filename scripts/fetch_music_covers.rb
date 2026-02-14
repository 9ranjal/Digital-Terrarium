#!/usr/bin/env ruby
# Fetches album cover URLs from MusicBrainz + Cover Art Archive for _data/music.yml.
# Run from repo root: ruby scripts/fetch_music_covers.rb
# Set REFRESH=1 to refetch all covers.

require "net/http"
require "json"
require "uri"

MUSIC_PATH = File.join(__dir__, "..", "_data", "music.yml")

def fetch_cover(title, artist)
  query = "artist:\"#{artist}\" AND release:\"#{title}\""
  url = URI("https://musicbrainz.org/ws/2/release/?query=#{URI.encode_www_form_component(query)}&fmt=json")
  req = Net::HTTP::Get.new(url)
  req["User-Agent"] = "JekyllBooksCovers/1.0"
  res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) { |http| http.request(req) }
  return nil unless res.is_a?(Net::HTTPSuccess)

  data = JSON.parse(res.body)
  release = data["releases"]&.first
  return nil unless release && release["id"]

  mbid = release["id"]
  cover_url = URI("https://coverartarchive.org/release/#{mbid}")
  req2 = Net::HTTP::Get.new(cover_url)
  req2["Accept"] = "application/json"
  res2 = Net::HTTP.start(cover_url.hostname, cover_url.port, use_ssl: true) { |http| http.request(req2) }
  return nil unless res2.is_a?(Net::HTTPSuccess)

  cover_data = JSON.parse(res2.body)
  img = cover_data["images"]&.find { |i| i["front"] } || cover_data["images"]&.first
  img&.dig("image")
end

content = File.read(MUSIC_PATH, encoding: "UTF-8")
refresh = ENV["REFRESH"] == "1"
updated = 0

blocks = content.split(/\n(?=- title:)/)
new_blocks = blocks.map do |block|
  next block unless block.strip.start_with?("- title:")

  cover_line = block[/cover:\s*["']?(.+?)["']?\s*$/m]
  has_cover = cover_line && $1.to_s.strip != ""
  skip = has_cover && !refresh
  if skip
    block
  else
    title = block[/title:\s*["']?(.+?)["']?\s*$/m] && $1&.strip
    artist = block[/artist:\s*["']?(.+?)["']?\s*$/m] && $1&.strip
    title = title.to_s.gsub(/^["']|["']\s*$/, "")
    artist = artist.to_s.gsub(/^["']|["']\s*$/, "")

    if title.empty? || artist.empty?
      block
    else
      cover = fetch_cover(title, artist)
      if cover
        updated += 1
        puts "  ✓ #{title}"
      else
        puts "  ✗ #{title} (no cover found)"
      end

      if cover
        block = block.lines.reject { |l| l.strip.start_with?("cover:") }.join
        if block =~ /(artist:\s*.+?\n)/
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

out = new_blocks.join("\n\n")
File.write(MUSIC_PATH, out, encoding: "UTF-8")
puts "\nUpdated #{updated} cover(s) in _data/music.yml"
