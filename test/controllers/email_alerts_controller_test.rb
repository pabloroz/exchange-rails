require "test_helper"

class EmailAlertsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @email_alert = @user.email_alerts.create!(
      base_currency: "USD",
      quote_currency: "EUR",
      multiplier: 1.2,
      comparison_operator: :greater_than,
      active: true
    )
    sign_in @user
    # Stub the external API request
    stub_request(:get, "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2024-12-05/v1/currencies/.json")
      .to_return(
        body: { "usd" => { "eur" => 1.2, "gbp" => 0.85 } }.to_json,
        status: 200,
        headers: { "Content-Type" => "application/json" }
      )
    (0...6).each do |days_ago|
      date = days_ago.days.ago.to_date.to_s
      stub_request(:get, "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@#{date}/v1/currencies/usd.json")
        .to_return(
          body: { "usd" => { "eur" => 1.2 } }.to_json,
          status: 200
        )
    end
  end

  test "should get index" do
    get email_alerts_url
    assert_response :success
  end

  test "should get new" do
    6.times do |days_ago|
      date = days_ago.days.ago.to_date.to_s
      stub_request(:get, "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@#{date}/v1/currencies/usd.json")
        .to_return(
          body: { "usd" => { "eur" => 1.9 } }.to_json,
          status: 200
        )
    end

    get new_email_alert_url
    assert_response :success
  end

  test "should create email_alert" do
    assert_difference("EmailAlert.count") do
      post email_alerts_url, params: { email_alert: { active: @email_alert.active, base_currency: @email_alert.base_currency, comparison_operator: @email_alert.comparison_operator, last_sent_at: @email_alert.last_sent_at, multiplier: @email_alert.multiplier, quote_currency: @email_alert.quote_currency, unsubscribed_at: @email_alert.unsubscribed_at, user_id: @email_alert.user_id } }
    end

    assert_redirected_to email_alert_url(EmailAlert.last)
  end

  test "should show email_alert" do
    get email_alert_url(@email_alert)
    assert_response :success
  end

  test "should get edit" do
    get edit_email_alert_url(@email_alert)
    assert_response :success
  end

  test "should update email_alert" do
    patch email_alert_url(@email_alert), params: { email_alert: { active: @email_alert.active, base_currency: @email_alert.base_currency, comparison_operator: @email_alert.comparison_operator, last_sent_at: @email_alert.last_sent_at, multiplier: @email_alert.multiplier, quote_currency: @email_alert.quote_currency, unsubscribed_at: @email_alert.unsubscribed_at, user_id: @email_alert.user_id } }
    assert_redirected_to email_alert_url(@email_alert)
  end

  test "should destroy email_alert" do
    assert_difference("EmailAlert.count", -1) do
      delete email_alert_url(@email_alert)
    end

    assert_redirected_to email_alerts_url
  end
end
