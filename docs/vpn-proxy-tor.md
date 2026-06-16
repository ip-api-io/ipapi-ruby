# VPN, proxy & Tor detection

Catch traffic that hides behind anonymizers. Every `lookup` already returns the
`suspicious_factors` flags for proxy, VPN, Tor, datacenter, spam and crawler; the
dedicated `tor_check` adds live Tor exit-node confirmation.

Powers [VPN detection](https://ip-api.io/vpn-detection-api),
[proxy detection](https://ip-api.io/proxy-detection-api) and
[Tor detection](https://ip-api.io/tor-detection).

## `suspicious_factors` — flags on every lookup

No extra call needed: read the flags from a normal [`lookup`](ip-geolocation.md).

```ruby
require "ip-api-io"

client = IpApiIo::Client.new(api_key: "YOUR_API_KEY")

info = client.lookup("185.220.101.1")
f = info["suspicious_factors"]

puts f["is_vpn"]         # VPN service
puts f["is_proxy"]       # open / anonymizing proxy
puts f["is_tor_node"]    # Tor node
puts f["is_datacenter"]  # hosting / datacenter IP (often a bot)
puts f["is_spam"]        # known spam source
puts f["is_crawler"]     # known crawler / bot
puts f["is_threat"]      # listed on a threat feed

if f["is_vpn"] || f["is_proxy"] || f["is_tor_node"]
  # require step-up verification
end
```

### `suspicious_factors`

| Field | Type | Meaning |
|---|---|---|
| `is_proxy` | Boolean | Open or anonymizing proxy |
| `is_vpn` | Boolean | Commercial VPN endpoint |
| `is_tor_node` | Boolean | Part of the Tor network |
| `is_datacenter` | Boolean | Hosting / datacenter range |
| `is_spam` | Boolean | Known spam source |
| `is_crawler` | Boolean | Known crawler / bot |
| `is_threat` | Boolean | Listed on a threat feed |

## `tor_check(ip)` — confirm a Tor exit node

A dedicated check against the live Tor node list, with a count of matching nodes.

```ruby
tor = client.tor_check("185.220.101.1")

puts tor["is_tor"]          # true
puts tor["tor_node_count"]  # number of matching Tor nodes
```

### Response (`TorDetection`)

| Field | Type | Description |
|---|---|---|
| `ip` | String | The checked IP |
| `is_tor` | Boolean | Whether the IP is a Tor node |
| `tor_node_count` | Integer | Matching nodes for the IP |

> Want one number instead of individual flags? See
> [Fraud detection & risk scoring](fraud-risk-scoring.md) — `risk_score` folds all of
> these signals into a 0–100 score.

## See also

- [IP geolocation & bulk lookup](ip-geolocation.md) — where `suspicious_factors` comes from
- [Fraud detection & risk scoring](fraud-risk-scoring.md) — combine the flags into a score
- Product pages: [VPN detection](https://ip-api.io/vpn-detection-api) · [Proxy detection](https://ip-api.io/proxy-detection-api) · [Tor detection](https://ip-api.io/tor-detection)
- [Full tutorial on ip-api.io](https://ip-api.io/docs/sdk/ruby/vpn-proxy-tor)
