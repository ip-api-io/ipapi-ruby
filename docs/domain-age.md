# Domain age checker

Newly registered domains are a strong fraud and spam signal. `domain_age` returns how
long ago a domain was registered, derived from WHOIS data, so you can flag or block
domains created days ago.

Powers the [domain age checker](https://ip-api.io/domain-age-checker).

## `domain_age(domain)` — age of one domain

```ruby
require "ip-api-io"

client = IpApiIo::Client.new(api_key: "YOUR_API_KEY")

age = client.domain_age("example.com")

puts age["is_valid"]           # true
puts age["registration_date"]  # "1995-08-14"
puts age["age_in_years"]       # 30
puts age["age_in_days"]        # 11000+

if (age["age_in_days"] || Float::INFINITY) < 30
  # treat brand-new domains as higher risk
end
```

### Response (`DomainAge`)

| Field | Type | Description |
|---|---|---|
| `domain` | String | The domain checked |
| `is_valid` | Boolean | Whether age could be determined |
| `registration_date` | String, nil | First registration date |
| `age_in_years` | Integer, nil | Age in whole years |
| `age_in_days` | Integer, nil | Age in days |
| `error` | String, nil | Reason when `is_valid` is false |

## `domain_age_batch(domains)` — many domains at once

Check an array of domains in one request (non-empty; raises `ArgumentError` if empty).

```ruby
batch = client.domain_age_batch([
  "example.com",
  "brand-new-domain.xyz",
])

batch["results"].each do |domain, age|
  puts "#{domain} #{age['age_in_days']}"
end
```

### Response (`BatchDomainAgeResponse`)
`results` — a Hash mapping each domain to its `DomainAge`.

## See also

- [ASN & DNS lookups](asn-and-dns.md) — `whois` for the full registration record
- [Fraud detection & risk scoring](fraud-risk-scoring.md) — combine age with other signals
- Product page: [Domain age checker](https://ip-api.io/domain-age-checker)
