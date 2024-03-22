require 'csv'
require 'pathname'

module Togodb
  class GuessColumnType
    NUM_CHECK_RECORDS = 10_000

    class DataIsEmpty < RuntimeError
    end

    class ColumnType
      class Fixed < RuntimeError
      end

      module Generalities
        class Text
        end
        class String < Text
        end
        class Time < String
        end
        class Date < Time
        end
        class DateTime < Time
        end
        class Float < String
        end
        class Decimal < Float
        end
        class Integer < Decimal
        end
        class BigInt < Integer
        end
        class Boolean < Integer
        end
      end

      def initialize
        @generality = nil
      end

      def <<(data)
        return seems Generalities::Text if data.size > 255

        case data.to_s.downcase
        when '0', '1', 't', 'f', 'true', 'false'
          seems Generalities::Boolean

        when /\A-?\d*\.\d+\Z/
          seems Generalities::Float

        when /\A-?\d+\Z/
          if data.to_s.size > 9
            seems Generalities::BigInt
          else
            seems Generalities::Integer
          end

        when %r[\A(\d){4}[-/](\d){1,2}[-/](\d){1,2}\z]
          seems Generalities::Date

        when %r[\A(\d){4}[-/](\d){1,2}[-/](\d){1,2}\s+(\d){1,2}:(\d){1,2}:(\d){1,2}([+-]\d{4})?\z]
          seems Generalities::DateTime

        when /\n/
          seems Generalities::Text

        else
          seems Generalities::String
        end
      end

      def type
        if @generality
          @generality.name.split(/::/).last.downcase
        else
          'text'
        end
      end

      private

      def current
        @generality
      end

      def seems(type)
        if current
          update_generality(current, type)
        else
          @generality = type
        end
        #--> raise Fixed if current == Generalities::Text
      end

      def update_generality(current, type)
        if type <= current
          # nop
        elsif current < type
          # tipe is more general than current
          @generality = type
        else
          # find an ancestor which these both types shares together
        end
      end

    end

    def initialize(file, options = {})
      @file = file
      @options = options

      raise DataIsEmpty unless @file

      if @options[:fs]
        @fs = @options[:fs]
      else
        @fs = ','
      end

      @csv_opts = {
        encoding: "#{@options[:csv_file_encoding]}:UTF-8",
        col_sep: @fs,
        liberal_parsing: true
      }

      if header?
        @header = first_entry
        @column_size = @header.size
      else
        @header = nil
        @column_size = first_entry.size
      end
    end

    # returns: ["string", "integer", ...] where types are kind of AR::ColumnType
    def execute(column_indexes = nil)
      guess(column_indexes).map(&:type)
    end

    private

    def header?
      @options[:header]
    end

    def guess(column_indexes = nil)
      if column_indexes.nil?
        col_ids = Array.new(@column_size) { |i| i }
      else
        col_ids = column_indexes
      end

      row_id = 0
      column_types = Array.new(col_ids.size).collect { ColumnType.new }

      CSV.foreach(@file, **@csv_opts) do |row|
        if header? && row_id.zero?
          row_id = 1
          next
        end

        col_ids.each_with_index do |col_id, i|
          data = row[col_id].to_s
          unless data.blank?
            column_types[i] << data
          end
        end

        row_id += 1
        break if row_id == NUM_CHECK_RECORDS
      end

      column_types
    end

    def first_entry
      entry = []
      CSV.foreach(@file, **@csv_opts) do |row|
        entry = row
        break
      end

      entry
    end

  end
end
