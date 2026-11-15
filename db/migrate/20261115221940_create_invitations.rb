class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :guest_name, null: false
      t.string :email
      t.string :access_token, null: false
      t.string :rsvp_status, null: false, default: "pending"
      t.string :venmo_username

      t.timestamps
    end
    add_index :invitations, :access_token, unique: true
    add_index :invitations, %i[event_id user_id], unique: true, where: "user_id IS NOT NULL"
  end
end
