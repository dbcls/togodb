module Togodb
  module Link

    def id_pattern_regexp(column)
      type_prop = Togodb::ColumnTypes.supported_types.select { |ct| ct[:name] == column.other_type }
      if type_prop.empty?
        nil
      else
        type_prop[0][:pattern]
      end
    end


    def xref_type_names
      Togodb::ColumnTypes.supported_types.select { |hash| !hash[:link].blank? }.map { |hash| hash[:name] }
    end

  end
end
