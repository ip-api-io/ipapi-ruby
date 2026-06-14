# Live smoke test against https://ip-api.io.
# Usage: IPAPI_API_KEY=... ruby -Ilib examples/smoke.rb
# The API requires a key; without IPAPI_API_KEY this script skips.
require_relative "../lib/ip-api-io"

api_key = ENV["IPAPI_API_KEY"]
if api_key.nil? || api_key.empty?
  puts "SKIPPED: set IPAPI_API_KEY to run the live smoke test"
  exit 0
end

client = IpApiIo::Client.new(api_key: api_key)

info = client.lookup("8.8.8.8")
raise "unexpected response: #{info.inspect}" unless info["ip"] == "8.8.8.8"
puts "lookup(8.8.8.8): #{info.dig('location', 'country')} / #{info['asn']}"

rl = client.rate_limit
puts "rate_limit: plan=#{rl['plan_id']} ip_api remaining=#{rl.dig('ip_api', 'remaining')}"

puts "smoke OK"
