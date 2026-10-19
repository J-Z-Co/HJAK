class CreateHealthTracker < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
      t.string :display_name, null: false, default: ""
      t.integer :sex
      t.date :birth_date
    end

    create_table :measurements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :metric_type, null: false
      t.date :recorded_on, null: false
      t.datetime :recorded_at, null: false
      t.decimal :value, precision: 6, scale: 1, null: false
      t.decimal :value_secondary, precision: 6, scale: 1
      t.uuid :idempotency_key, null: false
      t.timestamps
    end
    add_index :measurements, [ :user_id, :metric_type, :recorded_on, :recorded_at ]
    add_index :measurements, [ :idempotency_key, :metric_type ], unique: true

    create_table :groups do |t|
      t.string :name, null: false
      t.string :public_id, null: false
      t.timestamps
    end
    add_index :groups, :public_id, unique: true

    create_table :memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.datetime :joined_at, null: false
      t.timestamps
    end
    add_index :memberships, [ :group_id, :user_id ], unique: true
  end
end
