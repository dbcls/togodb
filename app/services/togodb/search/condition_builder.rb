module Togodb
  module Search
    class ConditionBuilder
      def initialize(model, simple_search = true, togodb_table_id = nil)
        @model = model
        @simple_search = simple_search
        @togodb_table_id = togodb_table_id
        init_field

        if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
          @like_op = 'ILIKE'
        else
          @like_op = 'LIKE'
        end
      end

      attr_accessor :simple_search_query

      def init_field
        @tokens = []
        @terms = []
        @operators = []
      end

      def build(search_values, columns)
        if @simple_search
          build_for_simple_search(search_values, columns)
        else
          build_for_luxury_search(search_values, columns)
        end
      end

      def build_for_simple_search(search_string, columns)
        if /\A\/(.+)\/i?\z/ =~ search_string
          columns.map { |column| condition_for_regexp($1, column, search_string[-1, 1] == 'i') }.join(' OR ')
        else
          parse(search_string)
          conditions_for_string(search_string, columns).map { |s| "(#{s})" }.join(' OR ')
        end
      end

      def build_for_luxury_search(search_values, columns)
        conditions = []
        columns.each do |column|
          query = search_values[column.internal_name]
          if column.has_data_type?
            query.strip! if query.is_a?(String)
            next if query.respond_to?('blank?') && query.blank?

            parse(query)
            condition = condition_for_string(query, column)
            init_field
          else
            case column.data_type
            when 'date' then
              condition = condition_for_date(query, column)
            when 'time' then
              condition = condition_for_time(query, column)
            when 'integer', 'bigint' then
              condition = condition_for_integer(query, column)
            when 'float', 'decimal' then
              condition = condition_for_numeric(query, column)
            when 'boolean' then
              condition = condition_for_boolean(query, column)
            else
              query.strip! if query.is_a?(String)
              next if query.respond_to?('blank?') && query.blank?

              if /\A\/(.+)\/i?\z/ =~ query
                condition = condition_for_regexp($1, column, query[-1, 1] == 'i')
              else
                if column.other_type == 'list'
                  condition = condition_for_list(query, column)
                else
                  parse(query)
                  condition = condition_for_string(query, column)
                end
                init_field
              end
            end
          end

          conditions << condition unless condition.blank?
        end

        conditions.map { |s| "(#{s})" }.join(' AND ')
      end

      def conditions_for_string(search_string, columns)
        conditions = []
        columns.each do |column|
          condition = condition_for_string(search_string, column)
          conditions << condition unless condition.blank?
        end

        conditions
      end

      def condition_for_string(search_string, column)
        condition = @terms[0].to_sql(@model, column_name_for_sql(column), @like_op, @simple_search)
        @terms[1..-1].zip(@operators).each do |term, operator|
          condition << " #{operator} #{term.to_sql(@model, column_name_for_sql(column), @like_op, @simple_search)}"
        end

        condition
      end

      def condition_for_regexp(search_string, column, ignore_case = false)
        dbname = ActiveRecord::Base.connection.adapter_name.downcase
        operator = 'LIKE'
        case dbname
        when 'mysql'
          operator = 'rLIKE'
        when 'sqlite3'
          operator = 'REGEXP'
        when 'postgresql'
          operator = if ignore_case
                       '~*'
                     else
                       '~'
                     end
        end

        @model.send(:sanitize_sql, [column_name_for_sql(column) + operator + '?', search_string])
      end

      def condition_for_list(search_string, column)
        @model.send(:sanitize_sql, [column_name_for_sql(column) + '=?', search_string])
      end

      def condition_for_integer(query, column)
        conditions = []

        if is_integer?(query['from'])
          conditions << column_name_for_sql(column) + '>=' + query['from']
        end

        if is_integer?(query['to'])
          conditions << column_name_for_sql(column) + '<=' + query['to']
        end

        conditions.join(' AND ')
      end

      def condition_for_numeric(query, column)
        conditions = []

        if is_numeric?(query['from'])
          conditions << column_name_for_sql(column) + '>=' + query['from'].strip
        end

        if is_numeric?(query['to'])
          conditions << column_name_for_sql(column) + '<=' + query['to'].strip
        end

        conditions.join(' AND ')
      end

      def condition_for_date(query, column)
        from = query['from']
        to = query['to']
        conditions = []

        unless empty_query?(from)
          fy = from['year'].blank? ? 1970 : from['year'].to_i
          fm = from['month'].blank? ? 1 : from['month'].to_i
          fd = from['day'].blank? ? 1 : from['day'].to_i
          if fy > 0 && fm > 0 && fd > 0
            conditions << column_name_for_sql(column) + '>=' + format("'%4d-%02d-%02d'", fy, fm, fd)
          end
        end

        unless empty_query?(to)
          ty = to['year'].blank? ? fy : to['year'].to_i
          tm = to['month'].blank? ? 12 : to['month'].to_i
          td = to['day'].blank? ? 31 : to['day'].to_i
          if ty.positive? && tm.positive? && td.positive?
            conditions << column_name_for_sql(column) + '<=' + format("'%4d-%02d-%02d'", ty, tm, td)
          end
        end

        conditions.join(' AND ')
      end

      def condition_for_time(query, column)
        from = query['from']
        to = query['to']
        conditions = []

        unless empty_query?(from)
          fh = from['hour'].blank? ? 0 : from['hour'].to_i
          fm = from['min'].blank? ? 0 : from['min'].to_i
          fs = from['sec'].blank? ? 0 : from['sec'].to_i
          conditions << column_name_for_sql(column) + '>=' + format("'%02d:%02d:%02d'", fh, fm, fs)
        end

        unless empty_query?(to)
          th = to['hour'].blank? ? 23 : to['hour'].to_i
          tm = to['min'].blank? ? 59 : to['min'].to_i
          ts = to['sec'].blank? ? 59 : to['sec'].to_i
          conditions << column_name_for_sql(column) + '<=' + format("'%02d:%02d:%02d'", th, tm, ts)
        end

        conditions.join(' AND ')
      end

      def condition_for_boolean(query, column)
        return '' if query.blank?

        dbname = ActiveRecord::Base.connection.adapter_name.downcase
        value = case dbname
                when 'postgresql' then
                  query.to_i == 1 ? 'true' : 'false'
                else
                  query
                end

        column_name_for_sql(column) + '=' + value
      end

      def parse(search_string)
        to_token(search_string)
        prev_term_is_operator = true
        @tokens.each do |tk|
          if prev_term_is_operator
            @terms << tk
            prev_term_is_operator = false
          else
            if tk.double_quoted || !(tk.value.upcase == 'AND' || tk.value.upcase == 'OR')
              @operators << 'AND'
              @terms << tk
              prev_term_is_operator = false
            else
              @operators << tk.value.upcase
              prev_term_is_operator = true
            end
          end
        end
      end

      def to_token(search_string)
        negative = false
        search_string.split(/\"/).map { |s| s.strip }.each_with_index do |w, i|
          next if w.empty?

          if w == '-'
            negative = true
            next
          end
          if i % 2 == 0
            w.split(/[\s　]+/).each do |t|
              if t == '-'
                negative = true
              else
                @tokens << Token.new(t, false, false)
                negative = false
              end
            end
          else
            # double quoted token
            @tokens << Token.new(w, true, negative)
            negative = false
          end
        end
      end

      def empty_query?(query)
        if query.is_a?(ActionController::Parameters)
          query.values.each do |v|
            return false unless v.blank?
          end
          true
        elsif query.is_a?(String)
          query.strip.blank?
        else
          true
        end
      end

      def column_name_for_sql(column)
        if column.is_a?(TogodbColumn)
          column.column_name_for_sql
        else
          %("#{column}")
        end
      end

      def is_integer?(v)
        if v.blank?
          false
        else
          begin
            Integer(v)
            true
          rescue ArgumentError
            false
          end
        end
      end

      def is_numeric?(v)
        if v.blank?
          false
        else
          begin
            Float(v)
            true
          rescue ArgumentError
            false
          end
        end
      end


      class Token
        def initialize(value, double_quoted, negative)
          @negative = if !double_quoted && !negative
                        /\A\-/ =~ value
                      else
                        negative
                      end

          @value = if double_quoted
                     value
                   else
                     @negative ? value[1..-1] : value
                   end

          @double_quoted = double_quoted
        end

        def to_sql(model, column_name, operation, simple_search = true)
          model.send(:sanitize_sql, condition_for(column_name, operation))
        end

        def condition_for(column_name, operation)
          statement = statement_for(column_name, operation)
          statement = format('NOT (%s)', statement) if @negative
          case operation.upcase
          when 'LIKE', 'ILIKE' then
            value = "%#{@value}%"
          else
            value = @value
          end

          [statement, value]
        end

        def statement_for(column_name, operation)
          format('%s %s ?', column_name, operation)
        end

        attr_accessor :value, :double_quoted, :negative
      end

    end
  end
end
