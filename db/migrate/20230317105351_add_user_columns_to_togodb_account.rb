class AddUserColumnsToTogodbAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :togodb_accounts, :flags, :string, null: false, default: '01'
    add_column :togodb_accounts, :tables, :string
    add_column :togodb_accounts, :deleted, :boolean, null: false, default: false
  end
end
