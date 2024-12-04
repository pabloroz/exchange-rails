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

  test "should_reactivate? always returns false for equal" do
    @inactive_alert.comparison_operator = :equal
    assert_not @inactive_alert.should_reactivate?(1.5), "should_reactivate? should always return false for equal operator"
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