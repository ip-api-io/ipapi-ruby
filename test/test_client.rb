require "json"
require "minitest/autorun"
require "webmock/minitest"

require_relative "../lib/ip-api-io"

# IpInfoV1Dto example from https://ip-api.io/openapi.json
IP_INFO_FIXTURE = {
  "ip" => "203.0.113.195",
  "isp" => "Comcast Cable Communications",
  "asn" => "AS7922",
  "suspicious_factors" => {
    "is_proxy" => false, "is_tor_node" => false, "is_spam" => false,
    "is_crawler" => false, "is_datacenter" => true, "is_vpn" => false, "is_threat" => false
  },
  "location" => {
    "country" => "United States", "country_code" => "US", "city" => "San Francisco",
    "latitude" => 37.7749, "longitude" => -122.4194, "zip" => "94105",
    "timezone" => "America/Los_Angeles", "local_time" => "2023-06-21T14:30:00-07:00",
    "local_time_unix" => 1_687_385_400, "is_daylight_savings" => true
  }
}.freeze

class TestClient < Minitest::Test
  def client(**kwargs)
    IpApiIo::Client.new(**kwargs)
  end

  def test_lookup_parses_response_and_sends_user_agent
    stub = stub_request(:get, "https://ip-api.io/api/v1/ip/203.0.113.195")
           .with(headers: { "User-Agent" => IpApiIo::USER_AGENT })
           .to_return(status: 200, body: JSON.generate(IP_INFO_FIXTURE))

    info = client.lookup("203.0.113.195")
    assert_equal IP_INFO_FIXTURE, info
    assert_requested stub
  end

  def test_api_key_sent_as_query_param
    stub = stub_request(:get, "https://ip-api.io/api/v1/ip")
           .with(query: { "api_key" => "secret123" })
           .to_return(status: 200, body: "{}")

    client(api_key: "secret123").lookup
    assert_requested stub
  end

  def test_email_path_is_url_encoded
    stub = stub_request(:get, "https://ip-api.io/api/v1/email/advanced/user%2Btag%40example.com")
           .to_return(status: 200, body: "{}")

    client.validate_email("user+tag@example.com")
    assert_requested stub
  end

  def test_batch_post_sends_json_body
    stub = stub_request(:post, "https://ip-api.io/api/v1/ip/batch")
           .with(
             body: JSON.generate({ ips: ["8.8.8.8", "1.1.1.1"] }),
             headers: { "Content-Type" => "application/json" }
           )
           .to_return(status: 200, body: '{"results": {}}')

    client.lookup_batch(["8.8.8.8", "1.1.1.1"])
    assert_requested stub
  end

  def test_batch_size_validation
    assert_raises(ArgumentError) { client.lookup_batch([]) }
    assert_raises(ArgumentError) { client.lookup_batch(["1.1.1.1"] * 101) }
    assert_raises(ArgumentError) { client.validate_email_batch([]) }
  end

  def test_429_raises_rate_limit_error_with_headers
    stub_request(:get, "https://ip-api.io/api/v1/ip/8.8.8.8")
      .to_return(
        status: 429,
        body: '{"message": "Rate limit exceeded"}',
        headers: {
          "x-ratelimit-limit" => "1000",
          "x-ratelimit-remaining" => "0",
          "x-ratelimit-reset" => "1718200000"
        }
      )

    error = assert_raises(IpApiIo::RateLimitError) { client.lookup("8.8.8.8") }
    assert_equal 429, error.status_code
    assert_equal 1000, error.limit
    assert_equal 0, error.remaining
    assert_equal 1_718_200_000, error.reset
    assert_includes error.message, "Rate limit exceeded"
  end

  def test_401_raises_authentication_error
    stub_request(:get, "https://ip-api.io/api/v1/ip")
      .with(query: { "api_key" => "bad" })
      .to_return(status: 401, body: '{"error": "Invalid API key"}')

    error = assert_raises(IpApiIo::AuthenticationError) { client(api_key: "bad").lookup }
    assert_equal 401, error.status_code
  end

  def test_400_raises_invalid_request_error
    stub_request(:get, "https://ip-api.io/api/v1/ip/not-an-ip")
      .to_return(status: 400, body: '{"message": "Invalid IP address"}')

    assert_raises(IpApiIo::InvalidRequestError) { client.lookup("not-an-ip") }
  end

  def test_500_raises_server_error
    stub_request(:get, "https://ip-api.io/api/v1/ip")
      .to_return(status: 500, body: "{}")

    assert_raises(IpApiIo::ServerError) { client.lookup }
  end
end
