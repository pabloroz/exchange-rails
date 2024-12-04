require "application_system_test_case"

class EmailAlertsTest < ApplicationSystemTestCase
  setup do
    @email_alert = email_alerts(:one)
  end

  test "visiting the index" do
    visit email_alerts_url
    assert_selector "h1", text: "Email alerts"
  end

  test "should create email alert" do
    visit email_alerts_url
    click_on "New email alert"

    check "Active" if @email_alert.active
    fill_in "Base currency", with: @email_alert.base_currency
    fill_in "Comparison operator", with: @email_alert.comparison_operator
    fill_in "Last sent at", with: @email_alert.last_sent_at
    fill_in "Multiplier", with: @email_alert.multiplier
    fill_in "Quote currency", with: @email_alert.quote_currency
    fill_in "Unsubscribed at", with: @email_alert.unsubscribed_at
    fill_in "User", with: @email_alert.user_id
    click_on "Create Email alert"

    assert_text "Email alert was successfully created"
    click_on "Back"
  end

  test "should update Email alert" do
    visit email_alert_url(@email_alert)
    click_on "Edit this email alert", match: :first

    check "Active" if @email_alert.active
    fill_in "Base currency", with: @email_alert.base_currency
    fill_in "Comparison operator", with: @email_alert.comparison_operator
    fill_in "Last sent at", with: @email_alert.last_sent_at
    fill_in "Multiplier", with: @email_alert.multiplier
    fill_in "Quote currency", with: @email_alert.quote_currency
    fill_in "Unsubscribed at", with: @email_alert.unsubscribed_at
    fill_in "User", with: @email_alert.user_id
    click_on "Update Email alert"

    assert_text "Email alert was successfully updated"
    click_on "Back"
  end

  test "should destroy Email alert" do
    visit email_alert_url(@email_alert)
    click_on "Destroy this email alert", match: :first

    assert_text "Email alert was successfully destroyed"
  end
end
