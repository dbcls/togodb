require 'json'

module Togodb::Search
  class Word
    attr_reader :double_quoted, :logical_ope, :is_not_operation

    def initialize(text, double_quoted, logical_ope, is_not_operation)
      @text = text
      @double_quoted = double_quoted
      @logical_ope = logical_ope
      @is_not_operation = is_not_operation
    end

    def regexp_operation?
      %r{\A/.+/i?\z} =~ @text
    end

    def regexp_operator
      if @text[-1, 1] == 'i'
        '~*'
      else
        '~'
      end
    end

    def operator(default_operator = 'ILIKE')
      if regexp_operation?
        regexp_operator
      else
        default_operator
      end
    end

    def text
      if regexp_operation?
        %r{\A/(.+)/i?\z} =~ @text
        $1.dup
      else
        @text
      end
    end
  end

  def search_records(db, search_condition_hash_ary, offset, limit, sort_order = 'ASC', sort_name = nil)
    unless sort_name
      pkey_colname = TogodbTable.actual_primary_key(db.name)
      sort_name = pkey_colname
    end

    columns = db.view_show_merged_ordered_columns
    colnames = columns.map { |c| %Q("#{c.internal_name}") }
    if pkey_colname
      select = if colnames.include?(pkey_colname)
                 colnames.join(',')
               else
                 %Q("#{pkey_colname}",) + colnames.join(',')
               end
    end
    conditions = data_search_conditions(search_condition_hash_ary)

    total = db.active_record.where(conditions).count
    if sort_name
      records = db.active_record.where(conditions).select(select).offset(offset).limit(limit).order(%Q("#{sort_name}" #{sort_order}))
    else
      records = db.active_record.where(conditions).select(select).offset(offset).limit(limit)
    end

    { total: total, records: records, columns: columns }
  end

  def columns_for_simple_search(qtype)
    case qtype
    when 'ALL'
      @table.simple_search_columns
    else
      [TogodbColumn.find(qtype)]
    end
  end

  def redis_key_for_search_condition(key)
    "search_condition_#{key}"
  end

  def search_condition_by_param(db, params)
    pkey_colname = TogodbTable.actual_primary_key(db.name)

    page = params[:page].blank? ? 1 : params[:page].to_i
    limit = params[:rp].blank? ? 15 : params[:rp].to_i
    sortname = params[:sortname].blank? ? pkey_colname : params[:sortname]
    sortorder = params[:sortorder].blank? ? 'ASC' : params[:sortorder]

    search_condition_hash_ary = search_condition_hash_ary_by_param(params)

    page_key = params[:togodb_view_page_key]
    if page_key
      search_condition = @redis.get redis_key_for_search_condition(page_key)
      unless search_condition.blank?
        search_condition = JSON.parse(search_condition)
        search_condition_hash_ary += search_condition['condition']
        page = search_condition['page']
      end
    end

    {
        page: page,
        offset: (page - 1) * limit,
        limit: limit,
        sortname: sortname,
        sortorder: sortorder,
        condition: search_condition_hash_ary,
        pkey: pkey_colname
    }
  end

  def search_condition_hash_ary_by_param(params)
    search_condition_hash_ary = []

    query = params['query'] || params[:query]
    qtype = params['qtype'] || params[:qtype]
    unless query.blank?
      columns = columns_for_simple_search(qtype).map(&:id)
      search_condition_hash_ary << { type: 'simple', search: query, columns: columns }
    end

    search = params['search'] || params[:search]
    if search.is_a?(ActionController::Parameters)
      search_condition_hash_ary << { type: 'advanced', search: search.to_unsafe_h }
    end

    search_condition_hash_ary
  end

  def data_search_conditions(search_condition_hash_ary)
    phases = []
    values = []

    search_condition_hash_ary.each do |s_condition|
      type = s_condition[:type] || s_condition['type']
      search = s_condition[:search] || s_condition['search']
      search = search.to_unsafe_h if search.is_a?(ActionController::Parameters)
      columns = s_condition[:columns] || s_condition['columns']

      case type
      when 'simple'
        query = search.strip
        conditions = stmt_array_for_string(query, columns, 'ILIKE')
        unless conditions.empty?
          phases << conditions[0, 1]
          conditions[1 .. -1].each do |v|
            values << v
          end
        end
      when 'exact'
        conditions = stmt_array_for_exact(search)
        unless conditions.empty?
          phases << conditions[0, 1]
          conditions[1 .. -1].each do |v|
            values << v
          end
        end
      when 'advanced'
        condition_builder = Togodb::Search::ConditionBuilder.new(@table.active_record, false, @table.id)
        condition_builder.simple_search_query = query unless query.blank?
        columns = search.keys.map { |cin| TogodbColumn.where(table_id: @table.id, internal_name: cin).first }
        conditions = condition_builder.build(search, columns)
        phases << conditions unless conditions.blank?
      end
    end

    if values.empty?
      phases.join(' AND ')
    else
      [phases.join(' AND ')] + values
    end
  end

  def stmt_array_for_exact(search_condition)
    stmts = []
    values = []
    search_condition.each do |key, value|
      column_name = key[0 .. -2]
      ope = key[-1, 1]
      ope << '=' if %w[< >].include?(ope)

      column = TogodbColumn.find_by(table_id: @table.id, internal_name: column_name)
      next if column.nil?

      if column.data_type == 'date' && ope == '=' && /\A(\d{4}\-\d{2}\-\d{2})\-(\d{4}\-\d{2}\-\d{2})\z/ =~ value
        stmts << %Q("#{column_name}">=?)
        values << $1 # from date
        stmts << %Q("#{column_name}"<=?)
        values << $2 # to date
      else
        if value[0, 1] == '/'
          # Regexp search
          if value[-2, 2] == '/i'
            # ignore case
            ope = '~*'
            value = value[1 .. -3]
          else
            ope = '~'
            value = value[1 .. -2]
          end
        end
        stmts << %Q("#{column_name}"#{ope}?)
        values << value
      end
    end

    [stmts.join(' AND ')] + values
  end

  def stmt_array_for_string(search_word, columns, operator)
    conditions = ['']

    to_words(search_word).each do |word|
      conditions[0] << " #{word.logical_ope} " if word.logical_ope.length > 0

      ope = word.operator(operator)
      conditions[0] << "(#{conditions_stmt(columns, ope, word.is_not_operation)})"

      columns.each do
        conditions << if like_operation?(ope)
                        "%#{word.text}%"
                      else
                        word.text
                      end
      end
    end

    conditions
  end

  def conditions_stmt(columns, operator, not_ope = false)
    columns.map do |column|
      if column.is_a?(Integer)
        togodb_column = TogodbColumn.find(column)
        "(#{condition_stmt togodb_column.column_name_for_sql, operator, not_ope})"
      else
        %Q|(#{condition_stmt "#{column}", operator, not_ope})|
      end
    end.join(' OR ')
  end

  def condition_stmt(column, operator, not_ope = false)
    stmt = "(#{column} #{operator} ?)"
    stmt = "NOT #{stmt}" if not_ope

    stmt
  end

  def to_words(search_string)
    search_string.strip!
    cur_state = :normal
    escaped = false
    double_quoted = false
    words = []
    word = ''
    operator = ''
    negative = false

    search_string.chars do |cstr|
      if escaped
        word << cstr
        escaped = false
      else
        if cur_state == :double_quoted
          if cstr == '"'
            cur_state = :normal
          elsif cstr == '\\'
            escaped = true
          else
            word << cstr
          end
        else
          if /[ 　]/ =~ cstr
            if word != ''
              if !double_quoted && operator?(word)
                operator = word.upcase
              else
                words << Word.new(word, double_quoted, operator, negative)
                operator = 'AND'
              end
              word = ''
              double_quoted = false
              negative = false
            end
          elsif cstr == '"'
            cur_state = :double_quoted
            double_quoted = true
          elsif cstr == '\\'
            escaped = true
          elsif cstr == '-'
            if word.length > 0
              word << cstr
            else
              negative = true
            end
          else
            word << cstr
          end
        end
      end
    end

    if word != ''
      if double_quoted || !operator?(word)
        words << Word.new(word, double_quoted, operator, negative)
      end
    end

    words
  end

  private

  def operator?(word)
    %w[AND OR].include?(word.upcase)
  end

  def like_operation?(operator)
    /like/i =~ operator
  end

  def not_operation?(word)
    word.length > 3 && word[0, 1] == '-'
  end

end
