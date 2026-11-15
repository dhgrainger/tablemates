class CreateSettlements < ActiveRecord::Migration[8.1]
  def change
    create_table :settlements do |t|
      t.references :event, null: false, foreign_key: true
      t.references :from_invitation, null: false, foreign_key: { to_table: :invitations }
      t.references :to_invitation, null: false, foreign_key: { to_table: :invitations }
      t.integer :amount_cents, null: false
      t.datetime :paid_at
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
