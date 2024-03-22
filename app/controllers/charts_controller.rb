class ChartsController < ApplicationController
  NUM_RANGES = 5.0

  def show
    @chart_type = params[:chart_type]
    @togodb_table = TogodbTable.find_by(name: params[:table])
    @togodb_column = TogodbColumn.find_by(name: params[:column], table_id: @togodb_table.id)
    @model = @togodb_table.active_record

    render json: select_data.to_json
  end

  def tab_contents
    @column = TogodbColumn.find(params[:column_id]);
    @chart = TogodbGraph.where(togodb_column_id: @column.id).order(:chart_type).reject { |chart| chart.embed_tag.blank? }.first
  end

  def form
    @chart = TogodbGraph.find(params[:id]);
  end

  def uncreated_form
    @column = TogodbColumn.find(params[:id])
    table = TogodbTable.find(@column.table_id)

    @metastanza_tag = case params[:chart_type]
                      when 'Barchart'
                        "<togostanza-barchart\n></togostanza-barchart>"
                      when 'Piechart'
                        "<togostanza-piechart\n></togostanza-piechart>"
                      when 'Linechart'
                        "<togostanza-linechart\n></togostanza-linechart>"
                      when 'Heatmap'
                        "<togostanza-heatmap\n></togostanza-heatmap>"
                      when 'Scatter plot'
                        "<togostanza-scatter-plot\n></togostanza-scatter-plot>"
                      when 'Layered graph'
                        "<togostanza-layered-graph\n></togostanza-layered-graph>"
                      when 'Force graph'
                        "<togostanza-force-graph\n></togostanza-force-graph>"
                      else
                        ''
                      end
    @css = case params[:chart_type]
           when 'Barchart'
             "#togodb-chart-#{table.name}-#{@column.name} togostanza-barchart {\n}"
           when 'Piechart'
             "#togodb-chart-#{table.name}-#{@column.name} togostanza-piechart {\n}"
           when 'Linechart'
             "#togodb-chart-#{table.name}-#{@column.name} togostanza-linechart {\n}"
           when 'Heatmap'
             "#togodb-chart-#{table.name}-#{@column.name} togostanza-heatmap {\n}"
           when 'Scatter plot'
             "#togodb-chart-#{table.name}-#{@column.name} togostanza-scatter-plot {\n}"
           when 'Layered graph'
             "#togodb-chart-#{table.name}-#{@column.name} togostanza-layered-graph {\n}"
           when 'Force graph'
             "#togodb-chart-#{table.name}-#{@column.name} togostanza-force-graph {\n}"
           else
             ''
           end

    render 'form'
  end

  private

  def select_data
    if @togodb_column.number?
      select_data_by_numerical_column
    elsif @togodb_column.list_type?
      select_data_by_list_column
    elsif @togodb_column.text?
      select_data_by_text_column
    elsif @togodb_column.boolean?
      select_data_by_boolean_column
    else
      []
    end
  end

  def select_data_by_numerical_column
    data_for_chart = []

    min_v = @model.minimum(@togodb_column.internal_name)
    max_v = @model.maximum(@togodb_column.internal_name)

    range = max_v - min_v
    range_unit = range / NUM_RANGES
    digits = find_digits(range_unit)

    range_unit = if digits.zero?
                   min_v = min_v.floor
                   max_v = max_v.ceil
                   range_unit.ceil
                 else
                   range_unit.ceil(digits)
                 end

    left_v = min_v
    right_v = min_v + range_unit
    while left_v < max_v
      value = if @chart_type == 'piechart'
                "#{left_v..right_v}"
              else
                left_v
              end

      cnt = @model.where(@togodb_column.internal_name => left_v..right_v).count
      data_for_chart << {
        @togodb_column.name => value,
        count: cnt
      }

      left_v = right_v
      right_v += range_unit
      right_v = right_v.ceil(digits) if digits.positive?
    end

    data_for_chart
  end

  def select_data_by_list_column
    data_for_chart = []
    TogodbColumnValue.where(column_id: @togodb_column.id).each do |record|
      value = record.value
      cnt = @model.where(@togodb_column.internal_name => value).count
      data_for_chart << {
        @togodb_column.name => value,
        count: cnt
      }
    end

    data_for_chart
  end

  def select_data_by_text_column
    data_for_chart = []
    @model.select(@togodb_column.internal_name).distinct.each do |record|
      value = record[@togodb_column.internal_name]
      cnt = @model.where(@togodb_column.internal_name => value).count
      data_for_chart << {
        @togodb_column.name => value,
        count: cnt
      }
    end

    return data_for_chart if data_for_chart.size <= 5

    refined = []
    data_for_chart.sort! { |a, b| b[:count] <=> a[:count] }
    5.times { refined << data_for_chart.shift }
    refined << {
      @togodb_column.name => 'Others',
      count: data_for_chart.map { |data| data[:count] }.sum
    }

    refined
  end

  def select_data_by_boolean_column
    num_true = @model.where(@togodb_column.internal_name => true).count
    num_false = @model.where(@togodb_column.internal_name => false).or(
      @model.where(@togodb_column.internal_name => nil)
    ).count

    [
      { @togodb_column.name => 'TRUE', count: num_true },
      { @togodb_column.name => 'FALSE', count: num_false }
    ]
  end

  def select_data0
    case @togodb_column.name
    when 'resolution'
      [
        {
          resolution: '0.5',
          count: 1
        },
        {
          resolution: '1.0',
          count: 37
        },
        {
          resolution: '1.5',
          count: 6
        },
        {
          resolution: '2.0',
          count: 34
        },
        {
          resolution: '2.5',
          count: 17
        },
        {
          resolution: '3.0',
          count: 2
        }
      ]
    when 'ex_method'
      [
        {
          ex_method: 'NEUTRON',
          count: 60
        },
        {
          ex_method: 'X-RAY',
          count: 37
        }
      ]
    else
      []
    end
  end

  def find_digits(v)
    tmp_v = v.clone
    digits = 0
    while tmp_v < 1
      digits += 1
      tmp_v *= 10
    end

    digits
  end
end
