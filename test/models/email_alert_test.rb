require "test_helper"

class EmailAlertTest < ActiveSupport::TestCase
  setup do
    user = users(:one)
    @active_alert = user.email_alerts.new(
      base_currency: "USD",
      quote_currency: "EUR",
      multiplier: 1.5,
      comparison_operator: :greater_than,
      active: true
    )

    @inactive_alert = user.email_alerts.new(
      base_currency: "USD",
      quote_currency: "EUR",
      multiplier: 1.5,
      comparison_operator: :greater_than,
      active: false
    )

    # Stub for exchange rates API
    @api_url = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json"
    stub_request(:get, @api_url).to_return(
      body: { "usd" => { "eur" => 1.3 } }.to_json,
      status: 200
    )
  end

  # Test for previous_triggers
  test "previous_triggers returns the last n days" do
    # Stub API responses for the last 8 days
    8.times do |days_ago|
      date = days_ago.days.ago.to_date.to_s
      stub_request(:get, "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@#{date}/v1/currencies/usd.json")
        .to_return(
          body: { "usd" => { "eur" => 1.9 } }.to_json,
          status: 200
        )
    end

    # Call the method
    result = @active_alert.previous_triggers(8)

    # Assert that the result contains data for the last 8 days
    assert_equal 8, result.count, "Expected 8 days of results"
    assert result.keys.all? { |date| Date.parse(date) }, "Expected all keys to be valid dates"
    assert result.values.all? { |data| data[:current_rate] == 1.9 }, "Expected all current rates to be 1.3"

    # Assert triggering logic
    assert result.values.first[:triggered], "Expected the first day to trigger"
    result.values[1..].each do |data|
      assert_not data[:triggered], "Expected subsequent days to not trigger unless reactivated"
    end
  end


  test "previous_triggers alternates triggered status based on exchange rate changes" do
    # Define rates over 8 days
    rates = [ 1.9, 1.1, 1.1, 2, 2.0, 0.8, 1.52, 1.2 ]

    # Stub API responses for each day
    rates.reverse.each_with_index do |rate, days_ago|
      date = days_ago.days.ago.strftime("%Y-%m-%d")
      stub_request(:get, "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@#{date}/v1/currencies/usd.json")
        .to_return(
          body: { "usd" => { "eur" => rate } }.to_json,
          status: 200
        )
    end

    # Call the method
    result = @active_alert.previous_triggers(8)

    # Assert that the result contains data for 8 days
    assert_equal 8, result.count, "Expected 8 days of results"
    assert result.keys.all? { |date| Date.parse(date) }, "Expected all keys to be valid dates"

    # Assert triggering logic
    expected_triggered = [ true, false, false, true, false, false, true, false ]
    result.values.each_with_index do |data, index|
      assert_equal rates[index], data[:current_rate], "Expected the rate for day #{index} to be #{rates[index]}"
      assert_equal expected_triggered[index], data[:triggered], "Expected triggered for day #{index} to be #{expected_triggered[index]}"
    end
  end

  test "previous_triggers includes today" do
    stub_request(:get, %r{https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@\d{4}-\d{2}-\d{2}/v1/currencies/usd.json})
      .to_return(body: { "usd" => { "eur" => 1.3 } }.to_json, status: 200)

    triggers = @active_alert.previous_triggers(3)

    assert_equal 3, triggers.count, "Expected 3 days including today"
    assert_includes triggers.keys, Date.today.to_s, "Expected today's date to be included"
  end

  # Tests for `should_trigger?`
  test "should_trigger? returns true for greater_than when rate exceeds multiplier" do
    assert @active_alert.should_trigger?(1.6), "should_trigger? should return true when rate is greater than multiplier"
  end

  test "should_trigger? returns false for greater_than when rate does not exceed multiplier" do
    assert_not @active_alert.should_trigger?(1.4), "should_trigger? should return false when rate is not greater than multiplier"
  end

  test "should_trigger? returns true for lower_than when rate is below multiplier" do
    @active_alert.comparison_operator = :lower_than
    assert @active_alert.should_trigger?(1.4), "should_trigger? should return true when rate is lower than multiplier"
  end

  test "should_trigger? returns false for lower_than when rate is not below multiplier" do
    @active_alert.comparison_operator = :lower_than
    assert_not @active_alert.should_trigger?(1.6), "should_trigger? should return false when rate is not lower than multiplier"
  end

  test "should_trigger? returns true for equal when rate equals multiplier" do
    @active_alert.comparison_operator = :equal
    assert @active_alert.should_trigger?(1.5), "should_trigger? should return true when rate equals multiplier"
  end

  test "should_trigger? returns false for equal when rate does not equal multiplier" do
    @active_alert.comparison_operator = :equal
    assert_not @active_alert.should_trigger?(1.6), "should_trigger? should return false when rate does not equal multiplier"
  end

  test "should_trigger? returns false if alert is inactive for greater_than" do
    assert_not @inactive_alert.should_trigger?(1.6), "should_trigger? should return false when alert is inactive"
  end

  test "should_trigger? returns true for equal when rate equals multiplier with matching decimal places" do
    @active_alert.multiplier = 1.123
    @active_alert.comparison_operator = :equal
    assert @active_alert.should_trigger?(1.123), "should_trigger? should return true when rate equals multiplier with matching decimals"
  end

  test "should_trigger? trims decimals to match the multiplier's precision" do
    @active_alert.multiplier = 1.123
    @active_alert.comparison_operator = :equal

    # Should match the multiplier when the rate has more decimals
    assert @active_alert.should_trigger?(1.1236), "should_trigger? should return true when the rate matches the multiplier after trimming extra decimals"

    # Should not match the multiplier when the rate has fewer decimals
    assert_not @active_alert.should_trigger?(1.12), "should_trigger? should return false when the rate does not match the multiplier's precision"
  end

  # Tests for `should_reactivate?`
  test "should_reactivate? returns true for greater_than when rate drops below multiplier and alert is inactive" do
    assert @inactive_alert.should_reactivate?(1.4), "should_reactivate? should return true when rate is below multiplier and alert is inactive"
  end

  test "should_reactivate? returns false for greater_than when rate does not drop below multiplier" do
    assert_not @inactive_alert.should_reactivate?(1.6), "should_reactivate? should return false when rate is not below multiplier"
  end

  test "should_reactivate? returns true for lower_than when rate rises above multiplier and alert is inactive" do
    @inactive_alert.comparison_operator = :lower_than
    assert @inactive_alert.should_reactivate?(1.6), "should_reactivate? should return true when rate is above multiplier and alert is inactive"
  end

  test "should_reactivate? returns false for lower_than when rate does not rise above multiplier" do
    @inactive_alert.comparison_operator = :lower_than
    assert_not @inactive_alert.should_reactivate?(1.4), "should_reactivate? should return false when rate is not above multiplier"
  end

  test "should_reactivate? always returns true for equal" do
    @inactive_alert.comparison_operator = :equal
    assert @inactive_alert.should_reactivate?(1.5), "should_reactivate? should always return false for equal operator"
  end

  # Tests for `active` scope
  test "active scope includes only active alerts" do
    @active_alert.save!
    @inactive_alert.save!

    active_alerts = EmailAlert.active
    assert_includes active_alerts, @active_alert, "active scope should include active alerts"
    assert_not_includes active_alerts, @inactive_alert, "active scope should not include inactive alerts"
  end

  # Validation tests
  test "validates presence of multiplier" do
    @active_alert.multiplier = nil
    assert_not @active_alert.valid?, "EmailAlert should be invalid without a multiplier"
    assert_includes @active_alert.errors[:multiplier], "can't be blank"
  end

  test "validates numericality of multiplier" do
    @active_alert.multiplier = -1.5
    assert_not @active_alert.valid?, "EmailAlert should be invalid with a multiplier less than or equal to 0"
    assert_includes @active_alert.errors[:multiplier], "must be greater than 0"
  end

  test "validates presence of comparison_operator" do
    @active_alert.comparison_operator = nil
    assert_not @active_alert.valid?, "EmailAlert should be invalid without a comparison_operator"
    assert_includes @active_alert.errors[:comparison_operator], "can't be blank"
  end

  test "reactivate! sets active to true" do
    assert_not @inactive_alert.active?, "Alert should initially be inactive"
    @inactive_alert.reactivate!
    assert @inactive_alert.reload.active?, "reactivate! should set active to true"
  end

  test "deactivate! sets active to false" do
    assert @active_alert.active?, "Alert should initially be active"
    @active_alert.deactivate!
    assert_not @active_alert.reload.active?, "deactivate! should set active to false"
  end
end
