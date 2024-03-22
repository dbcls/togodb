class AddCssToTogodbGraph < ActiveRecord::Migration[7.1]
  def change
    add_column :togodb_graphs, :css, :text
  end
end
