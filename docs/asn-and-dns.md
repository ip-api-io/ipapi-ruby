# ASN & DNS lookups

Resolve the network and DNS layer behind an IP or domain: which autonomous system
owns an address, who registered a domain, what a host's PTR record is, and which mail
servers a domain uses.

Powers [ASN lookup](https://ip-api.io/asn-lookup),
[WHOIS lookup](https://ip-api.io/whois-lookup),
[reverse DNS](https://ip-api.io/reverse-dns-lookup) and
[MX record lookup](https://ip-api.io/mx-record-lookup).

## `asn(ip)` — autonomous system for an IP

Returns the ASN, owning organization, network range and country for an IP — and
whether it belongs to a datacenter.

```ruby
require "ip-api-io"

client = IpApiIo::Client.new(api_key: "YOUR_API_KEY")

asn = client.asn("8.8.8.8")

puts asn["asn"]            # 15169
puts asn["organization"]  # "Google LLC"
puts asn["network"]       # "8.8.8.0/24"
puts asn["is_datacenter"] # true
puts asn["country_code"]  # "US"
```

### Response (`AsnLookup`)
`ip`, `asn`, `organization`, `network`, `is_datacenter`, `country`, `country_code`.

## `whois(domain)` — domain registration

WHOIS record for a domain: registrar, registration/expiry/update dates, name servers,
status codes and the raw WHOIS text.

```ruby
whois = client.whois("example.com")

puts whois["registrar"]["name"]
puts whois["registered_on"]     # "1995-08-14"
puts whois["expires_on"]
puts whois["name_servers"]      # ["a.iana-servers.net", ...]
puts whois["status"][0]["humanized"]
```

### Response (`Whois`)
`domain`, `registrar` (`name`, `url`, `iana_id`), `registered_on`, `expires_on`,
`updated_on`, `name_servers`, `status` (`code`, `humanized`), `raw`, `error`.

## `reverse_dns(ip)` — PTR record for an IP

```ruby
rdns = client.reverse_dns("8.8.8.8")

puts rdns["hostname"]    # "dns.google"
puts rdns["ptr_record"]
puts rdns["ttl"]
```

### Response (`ReverseDns`)
`ip`, `hostname`, `ptr_record`, `ttl`.

## `forward_dns(hostname)` — resolve a hostname to addresses

```ruby
fdns = client.forward_dns("dns.google")

fdns["addresses"].each do |record|
  puts "#{record['type']} #{record['address']} #{record['ttl']}" # "A" "8.8.8.8" 300
end
```

### Response (`ForwardDns`)
`hostname`, `addresses` (each `type`, `address`, `ttl`).

## `mx_records(domain)` — mail servers for a domain

```ruby
mx = client.mx_records("example.com")

mx["mx_records"].each do |record|
  puts "#{record['priority']} #{record['hostname']} #{record['ttl']}"
end
```

### Response (`MxLookup`)
`domain`, `mx_records` (each `priority`, `hostname`, `ttl`).

## See also

- [IP geolocation & bulk lookup](ip-geolocation.md) — geolocation for the same IP
- [Email validation & verification](email-validation.md) — MX records feed deliverability
- [Domain age checker](domain-age.md) — registration age from WHOIS data
- Product pages: [ASN lookup](https://ip-api.io/asn-lookup) · [WHOIS lookup](https://ip-api.io/whois-lookup) · [Reverse DNS](https://ip-api.io/reverse-dns-lookup) · [MX record lookup](https://ip-api.io/mx-record-lookup)
