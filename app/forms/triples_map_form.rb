class TriplesMapForm
  include ActiveModel::Model
  include MappingsHelper
  include TogoMapper::Namespace

  attr_accessor :subject
  attr_accessor :property_sets

  delegate :uri, :rdf_types, :label, :language, :condition, to: :subject, prefix: :subject, allow_nil: true

  validates :subject_uri_value, presence: { message: :not_blank }
  validate  :rdf_type_valid?
  validates :subject_label_value, presence: { message: :not_blank }
  validate  :property_set_valid?


  def initialize
    self.property_sets = []
  end

  def update!
    subject.update!

    property_sets.each(&:update!)
  end

  def subject_format_form_value
    subject.uri.class_map_property_id
  end

  def subject_format_property
    subject.uri.class_map_property.property
  end

  def subject_uri_value
    value = subject.uri.value

    if subject.uri.uri_pattern?
      if value.blank?
        ''
      else
        uri_for_disp(
            Togodb.d2rq_base_uri,
            namespace_prefixes_by_namespace_settings(subject.uri.class_map.work.id),
            value
        )
      end
    end

    value
  end

  def subject_label_value
    subject.label.value
  end

  def subject_lang_value
    subject.language.value
  end

  def subject_cond_value
    subject.condition.value
  end

  private

  def rdf_type_valid?
    if subject_rdf_types.select { |rdf_type| rdf_type.value.present? }.empty?
      errors.add(:subject_rdf_types, :at_least_one)
    end
  end

  def property_set_valid?
    property_sets.each do |property_set|
      next unless property_set.property_bridge.enable

      # Predicate
      if property_set.predicates.select { |predicate| predicate.value.present? }.empty?
        errors.add(:base, "#{property_set.property_bridge.real_column_name} : Predicate #{I18n.t('errors.messages.at_least_one')}")
      end

      # Object
      if property_set.object_value.value.blank?
        errors.add(:base, "#{property_set.property_bridge.real_column_name} : Object #{I18n.t('errors.messages.not_blank')}")
      end

      # Language, Datatype
      if !property_set.object_language.value.blank? && !property_set.object_datatype.value.blank?
        errors.add(:base, "#{property_set.property_bridge.real_column_name} : #{I18n.t('errors.messages.both_lang_datatype')}")
      end
    end
  end
end
