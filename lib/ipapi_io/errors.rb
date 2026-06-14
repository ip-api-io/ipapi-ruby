module IpApiIo
  # Base error for all ip-api.io client failures.
  class Error < StandardError
    attr_reader :status_code, :body

    def initialize(message, status_code: nil, body: nil)
      super(message)
      @status_code = status_code
      @body = body
    end
  end

  # HTTP 401/403 — missing or invalid API key.
  class AuthenticationError < Error; end

  # HTTP 429 — quota exhausted. Exposes the x-ratelimit-* response headers;
  # +reset+ is the unix timestamp when the quota renews. The client never retries.
  class RateLimitError < Error
    attr_reader :limit, :remaining, :reset

    def initialize(message, status_code: 429, body: nil, limit: nil, remaining: nil, reset: nil)
      super(message, status_code: status_code, body: body)
      @limit = limit
      @remaining = remaining
      @reset = reset
    end
  end

  # HTTP 400/404/422 — malformed input or unknown resource.
  class InvalidRequestError < Error; end

  # HTTP 5xx — ip-api.io server-side failure.
  class ServerError < Error; end
end
