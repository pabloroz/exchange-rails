class CreateEmailAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :email_alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :base_currency, null: false
      t.string :quote_currency, null: false
      t.integer :comparison_operator, null: false
      t.float :multiplier, null: false
      t.boolean :active, null: false, default: true
      t.timestamp :unsubscribed_at
      t.timestamp :last_sent_at

      t.timestamps
    end
  end
end
