class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.string :location
      t.string :invite_token, null: false
      t.string :status, null: false, default: "planning"
      t.boolean :round_to_whole_dollars, null: false, default: false
      t.integer :forgive_under_cents, null: false, default: 0

      t.timestamps
    end
    add_index :events, :invite_token, unique: true
  end
end
