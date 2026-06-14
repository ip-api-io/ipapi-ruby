# Email validation & verification

Check whether an email address is real, deliverable and safe to accept — before it
ever enters your database. The SDK exposes three levels: a fast syntax/MX/disposable
check, full SMTP verification, and a batch endpoint for cleaning whole lists.

Powers [email validation](https://ip-api.io/email-validation),
[advanced email validation](https://ip-api.io/advanced-email-validation),
[email verification](https://ip-api.io/email-verification-api),
[disposable email detection](https://ip-api.io/disposable-email-checker) and
[email list cleaning](https://ip-api.io/email-list-cleaning).

## `email_info(email)` — fast syntax, MX & disposable check

A lightweight check (no SMTP probe): validates syntax, confirms the domain has MX
records, and flags disposable/throwaway providers. Use it inline on sign-up forms.

```ruby
require "ip-api-io"

client = IpApiIo::Client.new(api_key: "YOUR_API_KEY")

info = client.email_info("user@example.com")

puts info["syntax"]["is_valid"]    # true
puts info["is_disposable"]         # false
puts info["has_mx_records"]        # true
puts info["mx_records"][0]["hostname"]
```

### Response (`EmailInfo`)

| Field | Type | Description |
|---|---|---|
| `email` | String | The address checked |
| `is_disposable` | Boolean | Throwaway / temporary provider |
| `has_mx_records` | Boolean | Domain can receive mail |
| `mx_records` | Array | Each: `priority`, `hostname`, `ttl` |
| `syntax` | Hash | `is_valid`, `domain`, `username`, `error_reasons` |

## `validate_email(email)` — full SMTP deliverability

Advanced verification that connects to the mail server to confirm the mailbox is
deliverable, and adds role-account, free-provider, catch-all and Gravatar signals.
Use it before sending important mail or accepting a paying customer.

```ruby
result = client.validate_email("user@example.com")

puts result["reachable"]             # "yes" | "no" | "unknown"
puts result["smtp"]["deliverable"]   # true
puts result["smtp"]["catch_all"]     # false
puts result["disposable"]            # false
puts result["role_account"]          # false  (e.g. info@, support@)
puts result["free"]                  # false  (e.g. gmail.com)
puts result["suggestion"]            # typo fix, e.g. "user@gmail.com"
```

### Response (`AdvancedEmailValidation`)

| Field | Type | Description |
|---|---|---|
| `email` | String | The address checked |
| `reachable` | String | `"yes"`, `"no"` or `"unknown"` |
| `syntax` | Hash | `username`, `domain`, `valid` |
| `smtp` | Hash, nil | `host_exists`, `deliverable`, `full_inbox`, `catch_all`, `disabled` |
| `gravatar` | Hash, nil | `has_gravatar`, `gravatar_url` |
| `suggestion` | String | Suggested correction for a likely typo |
| `disposable` | Boolean | Throwaway provider |
| `role_account` | Boolean | Role address (info@, sales@, …) |
| `free` | Boolean | Free webmail provider |
| `has_mx_records` | Boolean | Domain can receive mail |

## `validate_email_batch(emails)` — clean a list (≤100)

Advanced-validate up to 100 addresses in one request — the building block for
[email list cleaning](https://ip-api.io/email-list-cleaning). Raises `ArgumentError`
if the array is empty or longer than 100.

```ruby
batch = client.validate_email_batch([
  "user@example.com",
  "fake@mailinator.com",
  "info@example.org",
])

puts batch["totalProcessed"]          # 3
puts batch["successfulValidations"]   # 3

batch["results"].each do |email, result|
  puts "#{email} #{result['reachable']} #{result['disposable']}"
end
```

### Response (`BatchEmailValidationResponse`)

| Field | Type | Description |
|---|---|---|
| `results` | Hash | Map of email → result Hash |
| `totalProcessed` | Integer | Emails received |
| `successfulValidations` | Integer | Emails validated |
| `failedValidations` | Integer | Emails that errored |

## See also

- [Fraud detection & risk scoring](fraud-risk-scoring.md) — `email_risk_score` for a 0–100 score
- [ASN & DNS lookups](asn-and-dns.md) — `mx_records` to inspect a domain's mail servers
- Product pages: [Email validation](https://ip-api.io/email-validation) · [Advanced validation](https://ip-api.io/advanced-email-validation) · [Email verification API](https://ip-api.io/email-verification-api) · [Disposable email checker](https://ip-api.io/disposable-email-checker) · [Email list cleaning](https://ip-api.io/email-list-cleaning)
