class CreateNudges < ActiveRecord::Migration[8.1]
  def change
    create_table :nudges do |t|
      t.references :group, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :subject, null: false, foreign_key: { to_table: :users }
      t.date :nudged_on, null: false
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :nudges, [ :group_id, :actor_id, :subject_id, :nudged_on ], unique: true, name: "index_nudges_once_per_day"
  end
end
