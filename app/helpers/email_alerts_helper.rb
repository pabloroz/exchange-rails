module EmailAlertsHelper
  def comparison_operators
      EmailAlert.translated_comparison_operators.map { |translation, k, _| [ translation, k ] }
    end
end
