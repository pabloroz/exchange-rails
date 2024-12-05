require "net/http"

class ExchangeRateService
  def self.fetch_exchange_rates(base_currency, date = "latest")
    api_url = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@#{date}/v1/currencies/#{base_currency&.downcase}.json"

    begin
      response = Net::HTTP.get(URI(api_url))
      JSON.parse(response)[base_currency.downcase]
    rescue => e
      Rails.logger.error "Error fetching rates for #{base_currency}: #{e.message}"
      nil
    end
  end

  def self.fetch_exchange_rate(base_currency, quote_currency, date)
    fetch_exchange_rates(base_currency, date)&.[](quote_currency&.downcase)
  end
end
