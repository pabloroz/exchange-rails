require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one) # Replace with your fixture or factory setup
    @other_user = users(:two) # Another user for unauthorized access testing
    @email_alert = @user.email_alerts.create!(
      base_currency: "USD",
      quote_currency: "EUR",
      multiplier: 1.2,
      comparison_operator: :greater_than,
      active: true
    )
  end

  test "should destroy an alert successfully" do
    sign_in @user # Assuming Devise or similar authentication
    assert_difference "@user.email_alerts.count", -1 do
      get unsubscribe_url(id: @email_alert.id)
    end
  end

  test "should not destroy alert if it does not belong to the user" do
    sign_in @other_user
    assert_no_difference "@user.email_alerts.count" do
      get unsubscribe_url(id: @email_alert.id)
    end
  end

  test "should not destroy alert if alert does not exist" do
    sign_in @user
    assert_no_difference "@user.email_alerts.count" do
      get unsubscribe_url(id: "nonexistent")
    end
  end

  test "should not destroy alert if not authenticated" do
    assert_no_difference "EmailAlert.count" do
      get unsubscribe_url(id: @email_alert.id)
    end
  end
end
