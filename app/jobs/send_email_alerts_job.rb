class SendEmailAlertsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    CheckEmailAlertsService.new.call
  end
end
