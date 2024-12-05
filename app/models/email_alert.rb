class EmailAlert < ApplicationRecord
  include TranslateEnum

  scope :active, -> { where(active: true) }
  
  belongs_to :user
  enum :comparison_operator, [:greater_than, :lower_than, :equal], validate: true

  validates :multiplier, presence: true, numericality: { greater_than: 0 }
  validates :comparison_operator, presence: true
  validates :base_currency, :quote_currency, presence: true

  translate_enum :comparison_operator

  # Determines if the alert should trigger based on the current rate
  def should_trigger?(current_rate, current_active_status = active?)
    COMPARISON_OPERATORS.fetch(comparison_operator).call(current_rate, multiplier, current_active_status)
  end

  # Determines if the alert should become active again based on the current rate
  def should_reactivate?(current_rate, current_active_status = active?)
    REACTIVATION_OPERATORS.fetch(comparison_operator).call(current_rate, multiplier, current_active_status)
  end

  def reactivate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  # Fetches the triggering history for the last `number_of_days`
  def previous_triggers(number_of_days)
    return {} if base_currency.blank? || quote_currency.blank?
    active_status = true

    (0...number_of_days).to_a.reverse.each_with_object({}) do |day_offset, triggers|
      date = day_offset.days.ago.to_date
      current_rate = ExchangeRateService.fetch_exchange_rate(base_currency, quote_currency, date)

      if current_rate.nil?
        Rails.logger.warn "Rate not found for #{date}, base: #{base_currency}, quote: #{quote_currency}"
        next
      end
      triggers[date.to_s] = {
        current_rate: current_rate,
        triggered: should_trigger?(current_rate, active_status)
      }
      active_status = should_reactivate?(current_rate, active_status)
    end
  end

  def base_currency=(value)
    super(value.to_s.downcase)
  end

  def quote_currency=(value)
    super(value.to_s.downcase)
  end

  private

  # Hash mapping of operators to their logic for triggering
  COMPARISON_OPERATORS = {
    "greater_than" => ->(rate, multiplier, active) { active && rate > multiplier },
    "lower_than" => ->(rate, multiplier, active) { active && rate < multiplier },
    "equal" => ->(rate, multiplier, _active) {
      trim_decimals(rate, multiplier) == multiplier
    }
  }.freeze

  # Hash mapping of operators to their logic for reactivation
  REACTIVATION_OPERATORS = {
    "greater_than" => ->(rate, multiplier, active) { rate < multiplier },
    "lower_than" => ->(rate, multiplier, active) { rate > multiplier },
    "equal" => ->(_rate, _multiplier, _active) { true } # Equal does not support reactivation
  }.freeze

  # Trims decimals to match the precision of the multiplier (used only in :equal)
  def self.trim_decimals(rate, multiplier)
    decimals = multiplier.to_s.split('.').last&.size || 0
    factor = 10**decimals
    (rate * factor).to_i / factor.to_f
  end

end