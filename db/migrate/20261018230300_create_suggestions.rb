class CreateSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :suggestions }
      t.text :body, null: false
      t.integer :reasonable_count, null: false, default: 0
      t.integer :wrong_count, null: false, default: 0
      t.timestamps
    end
  end
end
