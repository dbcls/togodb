require 'tempfile'

module Togodb
  module DB
  end
end

module Togodb::DB::Pgsql
  include Togodb::StringUtils

  def indexes(table_name)
    indexes = []

    sql = <<EOS
SELECT
  cli.relname AS index_name,
  clt.relname AS table_name,
  attr.attname AS column_name,
  pg_get_indexdef(idx.indexrelid) AS definition
FROM
  pg_index idx
  JOIN pg_class cli ON (cli.oid = idx.indexrelid)
  JOIN pg_class clt ON (clt.oid = idx.indrelid)
  JOIN pg_attribute attr ON (clt.oid = attr.attrelid AND idx.indkey[0] = attr.attnum)
WHERE
  clt.relname = '#{table_name}'
EOS
    rs = ActiveRecord::Base.connection.execute(sql)
    rs.each do |row|
      indexes << {
          table_name: row['table_name'],
          index_name: row['index_name'],
          column_name: row['column_name'],
          definition: row['definition']
      }
    end

    indexes
  end

  def index_names(conn = nil)
    sql = "SELECT indexname FROM pg_indexes WHERE tablename='#{@table.name}'"

    if conn
      result = conn.exec(sql)
    else
      result = ActiveRecord::Base.connection.execute sql
    end

    result.map { |r| r['indexname'] }
  end

  def index_name(table_name, column_name, index_type = 'btree')
    "#{table_name}_#{column_name}_#{index_type}_idx"
  end

  def primary_key_name(table_name)
    "#{table_name}_pkey"
  end

  def sequence_name(table_name, column_name)
    "#{table_name}_#{column_name}_seq"
  end

  def create_sequence(table_name, column_name, cur_val = nil)
    seq_name = sequence_name(table_name, column_name)
    sql = "CREATE SEQUENCE #{seq_name}"

    unless cur_val
      sql = "SELECT setval('#{seq_name}', cur_val)"
    end

    seq_name
  end

  def create_btree_index(table_name, column_name, conn = nil)
    index_name = index_name(table_name, column_name)
    sql = "CREATE INDEX #{index_name} ON #{table_name} (#{column_name})"

    begin
      if conn
        conn.exec sql
      else
        ActiveRecord::Base.connection.execute sql
      end
    rescue
      sql = "CREATE INDEX #{index_name} ON  #{table_name} USING btree (md5(#{column_name}))"
      if conn
        conn.exec sql
      else
        ActiveRecord::Base.connection.execute sql
      end
    end
  end

  def create_gin_index(table_name, column_name, conn = nil)
    sql = "CREATE INDEX #{index_name(table_name, column_name, 'gin')} ON #{table_name} USING gin (#{column_name} gin_trgm_ops)"

    if conn
      conn.exec sql
    else
      ActiveRecord::Base.connection.execute sql
    end
  end

  def primary_key_infos(table_name)
    infos = []

    sql = <<EOS
SELECT
  attr.attname AS column_name,
  cons.conname AS constraint_name,
  type.typname AS type
FROM
  pg_constraint cons
  INNER JOIN pg_class cl ON cons.conrelid = cl.oid
  INNER JOIN pg_attribute attr ON attr.attrelid = cl.oid AND attr.attnum = cons.conkey[1]
  INNER JOIN pg_type type ON type.oid = attr.atttypid
WHERE cons.contype = 'p' AND cl.relname = '#{table_name}'
EOS
    rs = ActiveRecord::Base.connection.execute sql
    rs.each do |row|
      infos << {
          column_name: row['column_name'],
          constraint_name: row['constraint_name'],
          type: row['type']
      }
    end

    infos
  end

  def add_primary_key(table_name, column_name)
    ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} ADD CONSTRAINT #{primary_key_name(table_name)} PRIMARY KEY (#{column_name})"
  end

  def drop_primary_key(table_name, column_name, constraint_name = nil)
    constraint_name ||= primary_key_name(table_name)

    ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{constraint_name}"
    ActiveRecord::Base.connection.execute "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} DROP NOT NULL"
  end

  def change_primary_key(table_name, new_pkey_colname)
    primary_key_infos(table_name).each do |pkey|
      drop_primary_key(table_name, pkey[:column_name], pkey[:constraint_name])
    end

    add_primary_key(table_name, new_pkey_colname)
  end

  def table_size(table_name)
    sql = <<EOS
SELECT
  reltuples as rows,
  pg_relation_size(regclass(relname)) as bytes
FROM
  pg_class
WHERE
  relname = '#{table_name}'
EOS
    rs = ActiveRecord::Base.connection.execute sql

    { num_records: rs[0]['rows'], bytes: rs[0]['bytes'] }
  end

  def change_column_type(table_name, column_name, new_type)
    sql = "ALTER TABLE #{table_name} ALTER COLUMN #{quote column_name} TYPE #{new_type}"

    ActiveRecord::Base.connection.execute sql
  end

  def integer_pkey_table?(table_name)
    pkey_infos = primary_key_infos(table_name)

    pkey_infos.size == 1 && /\Aint\d+\z/ =~ pkey_infos[0][:type]
  end

  def num_records(table_name)
    rs = ActiveRecord::Base.connection.execute "SELECT COUNT(*) FROM #{quote table_name}"

    rs[0]['count'].to_i
  end

  def min_value(table_name, column_name)
    rs = ActiveRecord::Base.connection.execute "SELECT MIN(#{column_name}) FROM #{quote table_name}"
    rs[0]['min'].to_i
  end

  def max_value(table_name, column_name)
    rs = ActiveRecord::Base.connection.execute "SELECT MAX(#{column_name}) FROM #{quote table_name}"

    rs[0]['max'].to_i
  end

  def generate_csv(table_name, output_dir = '/tmp', opts = {})
    query_select = opts[:select] || '*'

    copy_query = "SELECT #{query_select} FROM #{table_name}"
    copy_query << " WHERE #{opts[:conditions]}" unless opts[:conditions].blank?
    copy_query << " ORDER BY #{opts[:order]}" unless opts[:order].blank?
    copy_query << " LIMIT #{opts[:limit]}" unless opts[:limit].blank?

    #csv_file = Tempfile.new ["togodb_dl_#{table_name}", '.csv'], output_dir
    csv_file = Rails.root.join('tmp', 'togodb', "togodb_dl_#{table_name}_#{random_str(8)}.csv")
    ActiveRecord::Base.connection.execute "COPY (#{copy_query}) TO '#{csv_file.to_path}' WITH CSV"

    csv_file.to_path
  end

  def copy_table(src_table_name, dst_table_name, num_per_copy, &block)
    num_copied = 0

    create_table_by_src_table src_table_name, dst_table_name
    copy_constraint src_table_name, dst_table_name
    if num_per_copy.positive?
      num_copied = copy_all_records src_table_name, dst_table_name, num_per_copy, block
    end

    num_copied
  end

  def create_table_by_src_table(src_table_name, dst_table_name)
    ActiveRecord::Base.connection.execute "CREATE TABLE #{quote dst_table_name} AS SELECT * FROM #{quote src_table_name} WHERE 1 = 0"
  end

  def copy_all_records(src_table_name, dst_table_name, limit, block)
    pkey_infos = primary_key_infos(src_table_name)
    if pkey_infos.empty?
      copy_all_records_by_no_pkey src_table_name, dst_table_name, limit, block
    else
      if integer_pkey_table?(src_table_name)
        copy_all_records_by_integer_pkey src_table_name, dst_table_name, limit, block
      else
        copy_all_records_by_non_integer_pkey src_table_name, dst_table_name, limit, block
      end
    end
  end

  def copy_all_records_by_integer_pkey(src_table_name, dst_table_name, limit, block)
    pkey_infos = primary_key_infos(src_table_name)
    pkey_colname = pkey_infos[0][:column_name]
    start = min_value(src_table_name, pkey_colname)
    max_v = max_value(src_table_name, pkey_colname)
    num_copied = 0

    tf = Tempfile.new('togodb_copy')
    loop do
      where = "#{quote pkey_colname} IN ("
      where << (start ... start + limit).map { |v| v }.join(',')
      where << ')'
      ActiveRecord::Base.connection.execute "COPY (SELECT * FROM #{quote src_table_name} WHERE #{where} ORDER BY #{quote pkey_colname}) TO '#{tf.path}'"
      if tf.size > 0
        n = copy_data_from_file(dst_table_name, tf.path)
        num_copied += n
        block.call num_copied if block
      end

      start += limit
      if start > max_v
        tf.close true
        break
      end
    end

    num_copied
  end

  def copy_all_records_by_non_integer_pkey(src_table_name, dst_table_name, limit, block)
    pkey_infos = primary_key_infos(src_table_name)
    pkey_col_name = pkey_infos.map { |pk| quote(pk[:column_name]) }.join(',')
    offset = 0
    num_copied = 0

    tf = Tempfile.new('togodb_copy')
    loop do
      ActiveRecord::Base.connection.execute "COPY (SELECT * FROM #{quote src_table_name} ORDER BY #{pkey_col_name} OFFSET #{offset} LIMIT #{limit}) TO '#{tf.path}'"
      if tf.size.positive?
        n = copy_data_from_file(dst_table_name, tf.path)
        num_copied += n
        block.call num_copied if block
        offset += limit
      else
        tf.close true
        break
      end
    end

    num_copied
  end

  def copy_all_records_by_no_pkey(src_table_name, dst_table_name, limit, block)
    num_copied = 0
    tf = Tempfile.new('togodb_copy')
    ActiveRecord::Base.connection.execute "COPY #{quote src_table_name} TO '#{tf.path}'"
    num_copied = copy_data_from_file(dst_table_name, tf.path)
    tf.close true

    num_copied
  end

  def copy_constraint(src_table_name, dst_table_name)
    pkey_infos = primary_key_infos(src_table_name)
    pkey_colnames = pkey_infos.map { |p| p[:column_name] }

    pkey_infos.each do |pkey|
      add_primary_key(dst_table_name, pkey[:column_name])
    end

    indexes(src_table_name).each do |idx|
      next if pkey_colnames.include?(idx[:column_name])

      #add_index(dst_table_name, idx[:column_name])
      sql = idx[:definition].clone.gsub(/\s+#{src_table_name}(.+_idx)\s+ON\s+(public\.)?#{src_table_name}\s+/) { " #{dst_table_name}#{$1} ON #{$2}#{dst_table_name} " }
      ActiveRecord::Base.connection.execute sql
    end

    copy_default_values(src_table_name, dst_table_name)
  end

  def copy_data_from_file(dst_table_name, fpath)
    rs = ActiveRecord::Base.connection.execute "COPY #{quote(dst_table_name)} FROM '#{fpath}'"

    rs.cmd_tuples
  end

  def copy_default_values(src_table_name, dst_table_name)
    default_values(src_table_name).each do |defv|
      if /\Anextval\('(.+)'/ =~ defv[:default]
        copy_sequence($1, dst_table_name, defv[:column_name])
      else
        ActiveRecord::Base.connection.execute "ALTER TABLE #{dst_table_name} ALTER COLUMN #{defv[:column_name]} SET DEFAULT #{defv[:default]}"
      end
    end
  end

  def copy_sequence(src_seq_name, dst_table_name, column_name)
    seq_name = sequence_name(dst_table_name, column_name)

    ActiveRecord::Base.connection.execute "CREATE SEQUENCE #{seq_name}"
    ActiveRecord::Base.connection.execute "SELECT setval('#{seq_name}', (SELECT last_value FROM #{src_seq_name}))"
    ActiveRecord::Base.connection.execute "ALTER TABLE #{dst_table_name} ALTER COLUMN #{column_name} SET DEFAULT nextval('#{seq_name}')"
    ActiveRecord::Base.connection.execute "ALTER SEQUENCE #{seq_name} OWNED BY #{dst_table_name}.#{column_name}"
  end

  def default_values(table_name)
    defvalues = []

    sql = <<EOS
SELECT
  attr.attname AS column_name,
  pg_get_expr(ad.adbin, ad.adrelid) AS default_value
FROM
  pg_attribute attr
  JOIN pg_attrdef ad ON attr.attrelid = ad.adrelid AND attr.attnum = ad.adnum
WHERE
  attr.attrelid = (SELECT oid FROM pg_class WHERE relname='#{table_name}')
EOS
    rs = ActiveRecord::Base.connection.execute sql
    rs.each do |row|
      defvalues << {
          column_name: row['column_name'],
          default: row['default_value']
      }
    end

    defvalues
  end

  def set_seq_value(src_table_name, dst_table_name)
    ar = ActiveRecord::Base.connection.execute("SELECT last_value FROM #{src_table_name}_id_seq")
    ActiveRecord::Base.connection.execute("SELECT setval('#{dst_table_name}_id_seq', #{ar[0]['last_value']})")
  end

  def quote(str)
    '"' + str + '"'
  end

end
