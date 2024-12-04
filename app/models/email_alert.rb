class EmailAlert < ApplicationRecord
  include TranslateEnum

  scope :active, -> { where(active: true) }
  
  belongs_to :user
  enum :comparison_operator, [:greater_than, :lower_than, :equal], validate: true

  validates :multiplier, presence: true, numericality: { greater_than: 0 }
  validates :comparison_operator, presence: true

  translate_enum :comparison_operator

  # Determines if the alert should trigger based on the current rate
  def should_trigger?(current_rate)
    COMPARISON_OPERATORS.fetch(comparison_operator).call(current_rate, multiplier, active?)
  end

  # Determines if the alert should become active again based on the current rate
  def should_reactivate?(current_rate)
    REACTIVATION_OPERATORS.fetch(comparison_operator).call(current_rate, multiplier, active?)
  end

  def reactivate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
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
    "greater_than" => ->(rate, multiplier, active) { !active && rate < multiplier },
    "lower_than" => ->(rate, multiplier, active) { !active && rate > multiplier },
    "equal" => ->(_rate, _multiplier, _active) { false } # Equal does not support reactivation
  }.freeze

  # Trims decimals to match the precision of the multiplier (used only in :equal)
  def self.trim_decimals(rate, multiplier)
    decimals = multiplier.to_s.split('.').last&.size || 0
    factor = 10**decimals
    (rate * factor).to_i / factor.to_f
  end
end