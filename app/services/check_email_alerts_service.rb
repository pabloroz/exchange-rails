class CheckEmailAlertsService
  def call
    # Group alerts by base currency to minimize API calls
    EmailAlert.distinct.pluck("lower(base_currency)").each do |base_currency|
      # Fetch all rates for this base currency
      rates = ExchangeRateService.fetch_exchange_rates(base_currency.downcase)

      next unless rates # Skip if API call failed

      # Process each email_alert for this base currency
      EmailAlert.where(base_currency: base_currency.downcase).find_each do |email_alert|
        current_rate = rates[email_alert.quote_currency.downcase]

        next unless current_rate

        process_email_alert(email_alert, current_rate)
      end
    end
  end

  private

  def process_email_alert(email_alert, current_rate)
    if email_alert.should_trigger?(current_rate)
      send_email_alert(email_alert, current_rate)
    elsif email_alert.should_reactivate?(current_rate)
      email_alert.reactivate!
    end
  end

  def send_email_alert(email_alert, current_rate)
    email_alert.deactivate!
    AlertMailer.with(email_alert: email_alert, current_rate: current_rate).alert_email.deliver_later
  end
end
