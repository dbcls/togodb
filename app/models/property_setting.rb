class PropertySetting < ApplicationRecord
  self.abstract_class = true

  def relative_uri(v)
    rel_uri = v

    if !v.blank? && (uri_pattern? || predicate?)
      base_uri = if base_uri.blank?
                   Togodb.d2rq_base_uri
                 else
                   self.base_uri
                 end

      unless base_uri.blank?
        pos = v.index(base_uri)
        if pos && pos == 0
          rel_uri = v[base_uri.size .. -1]
        end
      end
    end

    rel_uri
  end

  def to_relative_uri
    self.value = relative_uri(value)
  end

  def predicate?
    false
  end

end
