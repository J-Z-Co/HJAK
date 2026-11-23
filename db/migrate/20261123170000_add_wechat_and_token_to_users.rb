class AddWechatAndTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :openid, :string
    add_column :users, :api_token, :string

    add_index :users, :openid, unique: true
    add_index :users, :api_token, unique: true
  end
end
