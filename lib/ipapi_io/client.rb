require "json"
require "net/http"
require "uri"

require_relative "errors"
require_relative "version"

module IpApiIo
  # Client for the ip-api.io IP intelligence and email validation API.
  #
  #   client = IpApiIo::Client.new(api_key: "YOUR_API_KEY")
  #   client.lookup("8.8.8.8") #=> { "ip" => "8.8.8.8", "location" => {...}, ... }
  #
  # An API key is required by the live API — get a free key at https://ip-api.io.
  class Client
    BASE_URL = "https://ip-api.io".freeze
    MAX_BATCH_SIZE = 100

    def initialize(api_key: nil, base_url: BASE_URL, timeout: 10)
      @api_key = api_key
      @base_url = base_url.sub(%r{/+\z}, "")
      @timeout = timeout
    end

    # -- IP intelligence ------------------------------------------------------

    # Geolocation + threat intelligence for an IP (or the caller's IP when nil).
    def lookup(ip = nil)
      request(:get, ip ? "/api/v1/ip/#{encode(ip)}" : "/api/v1/ip")
    end

    # Look up to 100 IP addresses in a single request.
    def lookup_batch(ips)
      check_batch!(ips, "ips")
      request(:post, "/api/v1/ip/batch", body: { ips: ips })
    end

    def ip_reputation(ip)
      request(:get, "/api/v1/ip-reputation/#{encode(ip)}")
    end

    def tor_check(ip)
      request(:get, "/api/v1/tor/#{encode(ip)}")
    end

    def asn(ip)
      request(:get, "/api/v1/asn/#{encode(ip)}")
    end

    # -- Email validation -------------------------------------------------------

    # Syntax, disposability and MX analysis of an email address.
    def email_info(email)
      request(:get, "/api/v1/email/#{encode(email)}")
    end

    # Advanced validation including SMTP deliverability checks.
    def validate_email(email)
      request(:get, "/api/v1/email/advanced/#{encode(email)}")
    end

    # Advanced-validate up to 100 email addresses in a single request.
    def validate_email_batch(emails)
      check_batch!(emails, "emails")
      request(:post, "/api/v1/email/advanced/batch", body: { emails: emails })
    end

    # -- Risk scoring -----------------------------------------------------------

    # Fraud risk score for an IP (or the caller's IP when nil).
    def risk_score(ip = nil)
      request(:get, ip ? "/api/v1/risk-score/#{encode(ip)}" : "/api/v1/risk-score")
    end

    def email_risk_score(email)
      request(:get, "/api/v1/risk-score/email/#{encode(email)}")
    end

    # -- DNS & domains ----------------------------------------------------------

    def whois(domain)
      request(:get, "/api/v1/dns/whois/#{encode(domain)}")
    end

    def reverse_dns(ip)
      request(:get, "/api/v1/dns/reverse/#{encode(ip)}")
    end

    def forward_dns(hostname)
      request(:get, "/api/v1/dns/forward/#{encode(hostname)}")
    end

    def mx_records(domain)
      request(:get, "/api/v1/dns/mx/#{encode(domain)}")
    end

    def domain_age(domain)
      request(:get, "/api/v1/domain/age/#{encode(domain)}")
    end

    def domain_age_batch(domains)
      raise ArgumentError, "domains must not be empty" if domains.empty?

      request(:post, "/api/v1/domain/age/batch", body: { domains: domains })
    end

    # -- Account ----------------------------------------------------------------

    def rate_limit
      request(:get, "/api/v1/ratelimit")
    end

    def usage_summary
      request(:get, "/api/v1/usage/summary")
    end

    private

    def encode(value)
      URI.encode_uri_component(value.to_s)
    end

    def check_batch!(items, name)
      raise ArgumentError, "#{name} must not be empty" if items.empty?
      raise ArgumentError, "#{name} must contain at most #{MAX_BATCH_SIZE} items" if items.size > MAX_BATCH_SIZE
    end

    def request(method, path, body: nil)
      uri = URI("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(api_key: @api_key) if @api_key

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      klass = method == :post ? Net::HTTP::Post : Net::HTTP::Get
      req = klass.new(uri)
      req["User-Agent"] = USER_AGENT
      req["Accept"] = "application/json"
      if body
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end

      response = http.request(req)
      return parse_body(response.body) if response.is_a?(Net::HTTPSuccess)

      raise error_for(response)
    end

    def parse_body(raw)
      raw.nil? || raw.empty? ? nil : JSON.parse(raw)
    end

    def error_for(response)
      status = response.code.to_i
      raw = response.body.to_s
      message = begin
        parsed = JSON.parse(raw)
        parsed.is_a?(Hash) ? (parsed["message"] || parsed["error"]).to_s : ""
      rescue JSON::ParserError
        raw.strip[0, 200]
      end
      message = "HTTP #{status} from ip-api.io" if message.empty?

      case status
      when 401, 403
        AuthenticationError.new(message, status_code: status, body: raw)
      when 429
        RateLimitError.new(
          message,
          body: raw,
          limit: header_int(response, "x-ratelimit-limit"),
          remaining: header_int(response, "x-ratelimit-remaining"),
          reset: header_int(response, "x-ratelimit-reset")
        )
      when 400, 404, 422
        InvalidRequestError.new(message, status_code: status, body: raw)
      when 500..599
        ServerError.new(message, status_code: status, body: raw)
      else
        Error.new(message, status_code: status, body: raw)
      end
    end

    def header_int(response, name)
      value = response[name]
      Integer(value, 10)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
