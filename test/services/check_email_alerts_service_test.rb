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

    @service = CheckEmailAlertsService.new

    # Default stub for fetch_exchange_rates
    def @service.fetch_exchange_rates(_base_currency)
      { "eur" => 1.3 }
    end
  end

  test "sends email alert and deactivates alert when should_trigger? is true" do
    assert_changes -> { @active_alert.reload.active }, from: true, to: false do
      assert_enqueued_email_with AlertMailer, :alert_email, params: { email_alert: @active_alert, current_rate: 1.3 } do
        @service.call
      end
    end
  end

  test "reactivates alert when should_reactivate? is true" do
    assert_changes -> { @inactive_alert.reload.active }, from: false, to: true do
      @service.call
    end
  end

  test "does not send email or reactivate when neither condition is met" do
    @active_alert.update!(multiplier: 1.5)
    @inactive_alert.update!(multiplier: 1.1)

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_changes -> { @active_alert.reload.active } do
        assert_no_changes -> { @inactive_alert.reload.active } do
          @service.call
        end
      end
    end
  end

  test "skips processing when current_rate is nil" do
    def @service.fetch_exchange_rates(_base_currency)
      { "eur" => nil }
    end

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_changes -> { @active_alert.reload.active } do
        assert_no_changes -> { @inactive_alert.reload.active } do
          @service.call
        end
      end
    end
  end

  test "skips processing when rates are nil" do
    def @service.fetch_exchange_rates(_base_currency)
      nil
    end

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_changes -> { @active_alert.reload.active } do
        assert_no_changes -> { @inactive_alert.reload.active } do
          @service.call
        end
      end
    end
  end

end