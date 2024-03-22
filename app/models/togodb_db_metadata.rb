class TogodbDBMetadata < ApplicationRecord
  self.table_name = 'togodb_db_metadatas'

  class << self

    def creative_commons
      [
          { label: 'CC BY', image_url: 'http://i.creativecommons.org/l/by/3.0/88x31.png' },
          { label: 'CC BY-ND', image_url: 'http://i.creativecommons.org/l/by-nd/3.0/88x31.png' },
          { label: 'CC BY-SA', image_url: 'http://i.creativecommons.org/l/by-sa/3.0/88x31.png' },
          { label: 'CC BY-NC', image_url: 'http://i.creativecommons.org/l/by-nc/3.0/88x31.png' },
          { label: 'CC BY-NC-ND', image_url: 'http://i.creativecommons.org/l/by-nc-nd/3.0/88x31.png' },
          { label: 'CC BY-NC-SA', image_url: 'http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png' }
      ]
    end

  end


  def license_html
    if license_is_creative_commons?
      TogodbDBMetadata.creative_commons[creative_commons][:label]
    else
      licence
    end
  end

  def license_is_creative_commons?
    !creative_commons.nil? && creative_commons.positive?
  end

  def has_license?
    !creative_commons.nil?
  end

end
