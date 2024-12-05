require "test_helper"

class ExchangeRateServiceTest < ActiveSupport::TestCase
  setup do
    @base_currency = "USD"
    @quote_currency = "EUR"
    @date = Date.today
    @api_url = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@#{@date}/v1/currencies/#{@base_currency.downcase}.json"
  end

  test "fetch_exchange_rates returns rates for a valid base currency" do
      # Mock the API response
      stub_request(:get, @api_url).to_return(
        body: { "usd" => { "eur" => 1.2, "gbp" => 0.85 } }.to_json,
        status: 200
        )

      rates = ExchangeRateService.fetch_exchange_rates(@base_currency, @date)
      assert_not_nil rates, "Expected rates to be returned"
      assert_equal 1.2, rates["eur"]
      assert_equal 0.85, rates["gbp"]
  end

  test "fetch_exchange_rate returns a specific rate for a valid base and quote currency" do
      # Mock the API response
      stub_request(:get, @api_url).to_return(
        body: { "usd" => { "eur" => 1.2, "gbp" => 0.85 } }.to_json,
        status: 200
        )

      rate = ExchangeRateService.fetch_exchange_rate(@base_currency, @quote_currency, @date)
      assert_not_nil rate, "Expected a rate to be returned"
      assert_equal 1.2, rate
  end

  test "fetch_exchange_rates returns nil for an invalid base currency" do
      # Mock an error response
      stub_request(:get, @api_url).to_return(
        body: { "error" => "Invalid base currency" }.to_json,
        status: 400
        )

      rates = ExchangeRateService.fetch_exchange_rates(@base_currency, @date)
      assert_nil rates, "Expected rates to be nil for invalid base currency"
  end

  test "fetch_exchange_rate returns nil for an invalid quote currency" do
      # Mock the API response
      stub_request(:get, @api_url).to_return(
        body: { "usd" => { "eur" => 1.2, "gbp" => 0.85 } }.to_json,
        status: 200
        )

      rate = ExchangeRateService.fetch_exchange_rate(@base_currency, "INVALID", @date)
      assert_nil rate, "Expected rate to be nil for invalid quote currency"
  end

  test "fetch_exchange_rates handles network errors gracefully" do
      # Simulate a network error
      stub_request(:get, @api_url).to_raise(Errno::ECONNREFUSED)

      rates = ExchangeRateService.fetch_exchange_rates(@base_currency, @date)
      assert_nil rates, "Expected rates to be nil for network errors"
  end

  test "fetch_exchange_rates handles invalid JSON gracefully" do
      # Mock the API response with invalid JSON
      stub_request(:get, @api_url).to_return(
        body: "invalid json",
        status: 200
        )

      rates = ExchangeRateService.fetch_exchange_rates(@base_currency, @date)
      assert_nil rates, "Expected rates to be nil for invalid JSON"
  end

  test "fetch_exchange_rates returns nil for an invalid date" do
    invalid_date_url = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@1900-01-01/v1/currencies/usd.json"

    # Stub the specific invalid date URL
    stub_request(:get, invalid_date_url).to_return(
      body: { "error" => "Invalid date" }.to_json,
      status: 400
    )

    rates = ExchangeRateService.fetch_exchange_rates(@base_currency, Date.new(1900, 1, 1))
    assert_nil rates, "Expected rates to be nil for an invalid date"
  end
end
