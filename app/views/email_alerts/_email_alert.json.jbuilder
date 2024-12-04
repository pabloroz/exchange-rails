json.extract! email_alert, :id, :user_id, :base_currency, :quote_currency, :comparison_operator, :multiplier, :active, :unsubscribed_at, :last_sent_at, :created_at, :updated_at
json.url email_alert_url(email_alert, format: :json)
