class WidenMeasurementDecimals < ActiveRecord::Migration[8.1]
  def change
    change_column :measurements, :value, :decimal, precision: 6, scale: 2, null: false
    change_column :measurements, :value_secondary, :decimal, precision: 6, scale: 2
  end
end
