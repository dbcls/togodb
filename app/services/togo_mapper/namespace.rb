module TogoMapper
  module Namespace

    def namespaces_by_namespace_settings(work_id)
      not_default_nss = NamespaceSetting.where(work_id: work_id).reorder('id desc').select do |nss|
        !nss.namespace.is_default
      end.map do |nss|
        {
            id: nss.id,
            prefix: nss.namespace.prefix,
            uri: nss.namespace.uri,
            is_default: nss.namespace.is_default,
            is_ontology: nss.is_ontology
        }
      end

      default_nss = NamespaceSetting.where(work_id: work_id).order('id').select do |nss|
        nss.namespace.is_default
      end.map do |nss|
        {
            id: nss.id,
            prefix: nss.namespace.prefix,
            uri: nss.namespace.uri,
            is_default: nss.namespace.is_default,
            is_ontology: nss.is_ontology
        }
      end

      not_default_nss + default_nss
    end

    def namespace_prefixes_by_namespace_settings(work_id)
      NamespaceSetting.where(work_id: work_id).map { |nss| nss.namespace.prefix }
    end

  end
end
