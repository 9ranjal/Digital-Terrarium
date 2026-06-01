#!/usr/bin/env ruby
# Fetches album cover URLs from MusicBrainz + Cover Art Archive for _data/music.yml.
# Run from repo root: ruby scripts/fetch_music_covers.rb
# Set REFRESH=1 to refetch all covers.

require "net/http"
require "json"
require "uri"

MUSIC_PATH = File.join(__dir__, "..", "_data", "music.yml")

def cover_exists?(url_str)
  url = URI(url_str)
  req = Net::HTTP::Head.new(url)
  req["User-Agent"] = "JekyllBooksCovers/1.0"
  res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) { |http| http.request(req) }
  res.is_a?(Net::HTTPRedirection) || res.is_a?(Net::HTTPSuccess)
end

def fetch_cover(title, artist)
  query = "artist:\"#{artist}\" AND release:\"#{title}\""
  url = URI("https://musicbrainz.org/ws/2/release/?query=#{URI.encode_www_form_component(query)}&fmt=json")
  req = Net::HTTP::Get.new(url)
  req["User-Agent"] = "JekyllBooksCovers/1.0"
  res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) { |http| http.request(req) }
  return nil unless res.is_a?(Net::HTTPSuccess)

  data = JSON.parse(res.body)
  releases = data["releases"] || []

  releases.first(5).each do |release|
    mbid = release["id"]
    rgid = release.dig("release-group", "id")
    release_url = "https://coverartarchive.org/release/#{mbid}/front-500"
    return release_url if cover_exists?(release_url)
    if rgid
      rg_url = "https://coverartarchive.org/release-group/#{rgid}/front-500"
      return rg_url if cover_exists?(rg_url)
    end
  end
  nil
end

content = File.read(MUSIC_PATH, encoding: "UTF-8")
refresh = ENV["REFRESH"] == "1"
updated = 0

blocks = content.split(/\n(?=- title:)/)
new_blocks = blocks.map do |block|
  next block unless block.strip.start_with?("- title:")

  cover_line = block.each_line.find { |l| l.strip.start_with?("cover:") }
  has_cover = cover_line && cover_line.sub(/^\s*cover:\s*/, "").strip.gsub(/^["']|["']$/, "").strip != ""
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

out = new_blocks.map { |b| b.sub(/\n+\z/, "\n") }.join("\n")
File.write(MUSIC_PATH, out, encoding: "UTF-8")
puts "\nUpdated #{updated} cover(s) in _data/music.yml"
