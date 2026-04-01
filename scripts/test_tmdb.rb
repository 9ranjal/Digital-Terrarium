require "net/http"
require "uri"
require "json"

API_KEY = "5f2b19b28c5626c2b197ea35612aed1a"
title = "Good Fortune"
year = "2025"

params = { "api_key" => API_KEY, "query" => title, "year" => year }
uri = URI("https://api.themoviedb.org/3/search/movie?#{URI.encode_www_form(params)}")

puts "Fetching: #{uri}"
begin
  res = Net::HTTP.get_response(uri)
  puts "Response Code: #{res.code}"
  puts "Response Body: #{res.body}"
rescue StandardError => e
  puts "Error: #{e.class} - #{e.message}"
end
