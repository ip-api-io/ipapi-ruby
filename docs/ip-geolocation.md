# IP geolocation & bulk lookup

Turn any IP address into geolocation, network and threat intelligence. A single
`lookup` returns the country, city, coordinates, timezone, ISP and ASN of an IP,
plus the `suspicious_factors` flags used for fraud screening (proxy, VPN, Tor,
datacenter, spam, crawler, threat).

Powers the [IP geolocation API](https://ip-api.io/what-is-my-ip) and the
[bulk IP lookup](https://ip-api.io/bulk-ip-lookup) product.

## `lookup(ip = nil)` — geolocate one IP

Pass an IPv4/IPv6 address, or omit the argument to geolocate the caller's own IP.

```ruby
require "ip-api-io"

client = IpApiIo::Client.new(api_key: "YOUR_API_KEY")

info = client.lookup("8.8.8.8")

puts info["ip"]                              # "8.8.8.8"
puts info["isp"]                             # "Google LLC"
puts info["location"]["country"]             # "United States"
puts info["location"]["city"]                # "Mountain View"
puts "#{info['location']['latitude']}, #{info['location']['longitude']}"
puts info["location"]["timezone"]            # "America/Los_Angeles"
puts info["suspicious_factors"]["is_datacenter"] # true
```

```ruby
# Geolocate the machine making the request
me = client.lookup
puts "#{me['ip']} #{me['location']['country']}"
```

### Response (`IpInfo`)

| Field | Type | Description |
|---|---|---|
| `ip` | String | The looked-up address |
| `isp` | String, nil | Internet service provider |
| `asn` | String, nil | Autonomous system the IP belongs to |
| `location` | Hash | `country`, `country_code`, `city`, `latitude`, `longitude`, `zip`, `timezone`, `local_time`, `local_time_unix`, `is_daylight_savings` |
| `suspicious_factors` | Hash | `is_proxy`, `is_vpn`, `is_tor_node`, `is_datacenter`, `is_spam`, `is_crawler`, `is_threat` |

> The `suspicious_factors` block is the fastest way to flag risky traffic in one call.
> For a single 0–100 score, see [Fraud detection & risk scoring](fraud-risk-scoring.md);
> for the individual checks, see [VPN, proxy & Tor detection](vpn-proxy-tor.md).

## `lookup_batch(ips)` — geolocate up to 100 IPs

Look up to 100 addresses in one request — ideal for enriching logs, sign-up events or
historical data without a round trip per IP. Raises `ArgumentError` if the array is
empty or longer than 100.

```ruby
batch = client.lookup_batch(["8.8.8.8", "1.1.1.1", "9.9.9.9"])

puts batch["total_processed"]     # 3
puts batch["successful_lookups"]  # 3
puts batch["failed_lookups"]      # 0

batch["results"].each do |ip, info|
  puts "#{ip} #{info['location']['country']} #{info['suspicious_factors']['is_vpn']}"
end
```

### Response (`BatchIpLookupResponse`)

| Field | Type | Description |
|---|---|---|
| `results` | Hash | Map of IP → info Hash |
| `total_processed` | Integer | IPs received |
| `successful_lookups` | Integer | IPs resolved |
| `failed_lookups` | Integer | IPs that could not be resolved |

## See also

- [Fraud detection & risk scoring](fraud-risk-scoring.md) — turn the flags into a score
- [VPN, proxy & Tor detection](vpn-proxy-tor.md) — the individual threat checks
- [ASN & DNS lookups](asn-and-dns.md) — network ownership for an IP
- Product pages: [IP geolocation](https://ip-api.io/what-is-my-ip) · [Bulk IP lookup](https://ip-api.io/bulk-ip-lookup)
- [Full tutorial on ip-api.io](https://ip-api.io/docs/sdk/ruby/ip-geolocation)
