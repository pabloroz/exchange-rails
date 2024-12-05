class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable
  has_many :email_alerts
end
