class AddNameToTogodbAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :togodb_accounts, :name, :string
  end
end
