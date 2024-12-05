class UnsubscribesController < ApplicationController
  before_action :authenticate_user!

  def unsubscribe
    email_alert = current_user.email_alerts.find_by(id: params[:id])

    if email_alert
      email_alert.destroy
      redirect_to root_path, notice: "You have been unsubscribed from this alert."
    else
      redirect_to root_path, alert: "Alert not found or already unsubscribed."
    end
  end
end
