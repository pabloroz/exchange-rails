class AlertMailer < ApplicationMailer
  default from: "alerts@example.com"

  def alert_email
    @email_alert = params[:alert]
    @current_rate = params[:current_rate]
    mail(
      to: @email_alert.user.email,
      subject: "Currency Alert: #{@email_alert.base_currency}/#{@email_alert.quote_currency} has reached #{@current_rate}"
    )
  end
end
