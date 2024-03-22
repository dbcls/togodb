require 'acts_as_bits'

class TogodbColumn < ApplicationRecord

  include ActsAsBits
  include Togodb::Link

  acts_as_bits :actions, %w[list show search luxury], prefix: true
  acts_as_bits :roles, %w[primary_key record_name sanitize sorting indexing]
  acts_as_bits :web_services, %w[genbank_entry_text genbank_entry_xml genbank_seq_fasta
                                 pubmed_abstract embl_entry_text embl_entry_xml embl_seq_fasta
                                 ddbj_entry_text ddbj_entry_xml ddbj_seq_fasta]


  before_update do |column|
    if Togodb::ColumnTypes.other_types.include?(column.data_type)
      other_type = column.data_type
      column.other_type = other_type
      column.data_type = Togodb::ColumnTypes.type_for_migrate(column.other_type)
    end

    if Togodb::ColumnTypes.bio_types.include?(column.other_type) && column.html_link_prefix.blank?
      column.html_link_prefix = Togodb::ColumnTypes.link_template(column.other_type, column.name)
    end
  end


  class << self

    def default_values(table, data_type, other_type = nil)
      b_search = if other_type.to_s == 'sequence'
                   false
                 else
                   (/^(string|text)$/ === data_type.to_s)
                 end

      {
          table_id: table.id,
          enabled: true,
          sanitize: true,
          position: table.columns.map { |c| c.position.nil? ? 0 : c.position }.sort[-1] + 1,
          action_list: table.columns.select(&:action_list).size < 5,
          action_show: true,
          action_search: b_search,
          action_luxury: b_search
      }
    end

  end


  def data_type_label
    if Togodb::ColumnTypes.other_types.include?(other_type) || other_type == 'sequence'
      other_type
    else
      data_type
    end
  end

  def column_name_for_sql
    if has_data_type? && number?
      %Q|CAST("#{internal_name}" AS VARCHAR(255))|
    else
      %Q("#{internal_name}")
    end
  end

  def text?
    %w[string text].include?(data_type.to_s)
  end

  def number?
    %w[float integer decimal].include?(data_type.to_s)
  end

  def list_type?
    other_type == 'list'
  end

  def boolean?
    data_type == 'boolean'
  end

  def has_data_type?
    !other_type.to_s.strip.empty?
  end

  def has_link?
    !html_link_prefix.to_s.strip.empty?
  end

  def has_id_separator?
    id_separator.present?
  end

  def sequence_type?
    other_type == 'sequence'
  end

  def web_service?
    !self[:web_services].blank? && !self[:web_services].index('1').nil?
  end

  def has_rdf_property?
    !rdf_p_property.to_s.strip.empty?
  end

  def has_rdf_class?
    !rdf_o_class.to_s.strip.empty?
  end

  def xref?
    xref_type_names.include?(other_type)
  end

  def support_text_search?
    text? || has_data_type?
  end

end
