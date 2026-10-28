module Togodb
  class DataTables
    include ActionView::Helpers::NumberHelper

    def initialize(datatables_params)
      @records = []
      @params = datatables_params
      @query = datatables_params[:sSearch].blank? ? nil : @params[:sSearch].strip
      @filtered_total = nil
    end

    def minimum_data
      {
          sEcho: @params[:sEcho],
          iTotalRecords: total_size,
          iTotalDisplayRecords: @filtered_total,
          aaData: []
      }
    end

    def list_data
      data = minimum_data
      list_records.each do |table|
        aa_data = []
        columns.each do |column|
          aa_data << eval("#{column[:method]}(table)")
        end
        data[:aaData] << aa_data
      end
      data[:iTotalDisplayRecords] = @filtered_total

      data
    end

    def list_conditions
      nil
    end

    def num_sort_columns
      @params[:iSortingCols].blank? ? 0 : @params[:iSortingCols].to_i
    end

    def sort_field(sort_number)
      columns[@params["iSortCol_#{sort_number}"].to_i][:name]
    end

    def sort_dir(sort_number)
      @params["sSortDir_#{sort_number}"]
    end

    def list_offset
      @params[:iDisplayStart].blank? ? 0 : @params[:iDisplayStart].to_i
    end

    def list_limit
      @params[:iDisplayLength].blank? ? nil : @params[:iDisplayLength].to_i
    end

    def columns
      self.class.columns
    end

    def total_size
    end

  end
end
