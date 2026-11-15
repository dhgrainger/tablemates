class CreateContributions < ActiveRecord::Migration[8.1]
  def change
    create_table :contributions do |t|
      t.references :event, null: false, foreign_key: true
      t.references :invitation, foreign_key: true
      t.string :name, null: false
      t.string :category, null: false, default: "other"
      t.integer :cost_cents, null: false, default: 0
      t.boolean :shared, null: false, default: true

      t.timestamps
    end
  end
end
