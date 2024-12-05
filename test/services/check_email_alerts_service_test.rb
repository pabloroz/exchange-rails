require "test_helper"

class CheckEmailAlertsServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = users(:one)

    # Common email alerts for tests
    @active_alert = @user.email_alerts.create!(
      base_currency: "USD",
      quote_currency: "EUR",
      multiplier: 1.2,
      comparison_operator: :greater_than,
      active: true
    )

    @inactive_alert = @user.email_alerts.create!(
      base_currency: "USD",
      quote_currency: "EUR",
      multiplier: 1.4,
      comparison_operator: :greater_than,
      active: false
    )

    # Stub for exchange rates API
    @api_url = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json"
    stub_request(:get, @api_url).to_return(
      body: { "usd" => { "eur" => 1.3 } }.to_json,
      status: 200
    )


    @check_email_alerts_service = CheckEmailAlertsService.new()
  end

  test "sends email alert and deactivates alert when should_trigger? is true" do
    assert_changes -> { @active_alert.reload.active }, from: true, to: false do
      assert_enqueued_email_with AlertMailer, :alert_email, params: { email_alert: @active_alert, current_rate: 1.3 } do
        @check_email_alerts_service.call
      end
    end
  end

  test "reactivates alert when should_reactivate? is true" do
    assert_changes -> { @inactive_alert.reload.active }, from: false, to: true do
      @check_email_alerts_service.call
    end
  end

  test "does not send email or reactivate when neither condition is met" do
    @active_alert.update!(multiplier: 1.5)
    @inactive_alert.update!(multiplier: 1.1)

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_changes -> { @active_alert.reload.active } do
        assert_no_changes -> { @inactive_alert.reload.active } do
          @check_email_alerts_service.call
        end
      end
    end
  end

  test "skips processing when current_rate is nil" do
    # Stub for exchange rates API
    stub_request(:get, @api_url).to_return(
      body: { "usd" => nil }.to_json,
      status: 200
    )

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_changes -> { @active_alert.reload.active } do
        assert_no_changes -> { @inactive_alert.reload.active } do
          @check_email_alerts_service.call
        end
      end
    end
  end

  test "skips processing when rates are nil" do
    @api_url = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json"
    stub_request(:get, @api_url).to_return(
      body: {}.to_json,
      status: 200
    )

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_changes -> { @active_alert.reload.active } do
        assert_no_changes -> { @inactive_alert.reload.active } do
          @check_email_alerts_service.call
        end
      end
    end
  end
end
