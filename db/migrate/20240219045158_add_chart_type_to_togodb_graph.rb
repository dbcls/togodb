class AddChartTypeToTogodbGraph < ActiveRecord::Migration[7.1]
  def change
    add_column :togodb_graphs, :chart_type, :string
  end
end
