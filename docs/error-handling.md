# Errors, rate limits & usage

The client raises a typed error for every HTTP failure and **never retries** — you
stay in control of back-off. It also exposes your current quota so you can throttle
before you hit a limit.

## Error taxonomy

Every error extends `IpApiIo::Error`, which carries `status_code` and the raw response
`body`. Rescue the specific subclass you care about:

| Error | HTTP status | Meaning |
|---|---|---|
| `IpApiIo::AuthenticationError` | 401, 403 | Missing or invalid API key |
| `IpApiIo::RateLimitError` | 429 | Quota exhausted (see below) |
| `IpApiIo::InvalidRequestError` | 400, 404, 422 | Malformed input or unknown resource |
| `IpApiIo::ServerError` | 5xx | ip-api.io server-side failure |
| `IpApiIo::Error` | other | Base / fallback |

```ruby
require "ip-api-io"

client = IpApiIo::Client.new(api_key: "YOUR_API_KEY")

begin
  info = client.lookup("8.8.8.8")
  puts info["location"]["country"]
rescue IpApiIo::RateLimitError => e
  puts "quota hit — resets at #{e.reset}"
rescue IpApiIo::AuthenticationError
  puts "check your API key"
rescue IpApiIo::InvalidRequestError => e
  puts "bad request: #{e.message}"
rescue IpApiIo::ServerError
  puts "ip-api.io is having trouble, try later"
rescue IpApiIo::Error => e
  puts "error #{e.status_code}: #{e.message}"
end
```

Transport failures (DNS, connection, timeout) surface as the standard library's
`Net::OpenTimeout` / `SocketError`, not an `IpApiIo::Error`.

## Rate limits

On HTTP 429 the client raises `RateLimitError`, parsed from the `x-ratelimit-*`
response headers. Because the client never retries, **`reset` tells you when to**:

```ruby
begin
  client.lookup("8.8.8.8")
rescue IpApiIo::RateLimitError => e
  puts e.limit      # your quota for the window
  puts e.remaining  # requests left (0 here)
  puts e.reset      # unix timestamp when quota renews
  wait = (e.reset || 0) - Time.now.to_i
  # schedule a retry after `wait` seconds instead of hammering the API
end
```

## `rate_limit` — check quota proactively

Read your current limits without triggering a 429, so you can throttle in advance.

```ruby
rl = client.rate_limit

puts rl["plan_name"]
puts "#{rl['ip_api']['remaining']} / #{rl['ip_api']['limit']}"
puts "#{rl['email_api']['usage_percent']} % used"
puts rl["next_renewal_date"]
```

`RateLimitInfo`: `plan_id`, `plan_name`, `ip_api` and `email_api`
(`limit`, `remaining`, `used`, `usage_percent`), `interval_seconds`,
`next_renewal_date`, `status`.

## `usage_summary` — account usage

Aggregate usage for the current period — handy for dashboards and internal alerts.

```ruby
usage = client.usage_summary

puts "#{usage['totalRequests']} #{usage['successfulRequests']}"
puts "#{usage['rateLimitedRequests']} #{usage['quotaConsumed']}"
puts "#{usage['periodStart']} → #{usage['periodEnd']}"
```

`UsageSummary`: `apiKey`, `apiType`, `periodStart`, `periodEnd`, `totalRequests`,
`successfulRequests`, `rateLimitedRequests`, `quotaConsumed`, `batchOperations`,
`avgRequestDurationMs`.

## See also

- [IP geolocation & bulk lookup](ip-geolocation.md) — the most common call
- API reference: https://ip-api.io/api-docs.html
- Get a free API key: https://ip-api.io
