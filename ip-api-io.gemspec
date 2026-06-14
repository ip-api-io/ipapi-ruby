require_relative "lib/ipapi_io/version"

Gem::Specification.new do |spec|
  spec.name = "ip-api-io"
  spec.version = IpApiIo::VERSION
  spec.authors = ["ip-api.io"]
  spec.summary = "Official Ruby client for ip-api.io — IP geolocation, email validation, fraud detection and risk scoring API"
  spec.description = "Ruby client for the ip-api.io IP intelligence platform: IP geolocation, " \
                     "email validation (syntax, MX, SMTP deliverability), fraud detection and risk scoring, " \
                     "VPN/proxy/Tor detection, ASN lookup, WHOIS, reverse/forward DNS and domain age. " \
                     "Zero runtime dependencies."
  spec.homepage = "https://ip-api.io"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri" => "https://ip-api.io",
    "documentation_uri" => "https://ip-api.io/docs",
    "source_code_uri" => "https://github.com/ip-api-io/ipapi-ruby",
    "changelog_uri" => "https://github.com/ip-api-io/ipapi-ruby/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/ip-api-io/ipapi-ruby/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb"] + %w[README.md CHANGELOG.md LICENSE]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.24"
end
