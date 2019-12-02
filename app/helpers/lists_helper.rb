module ListsHelper

  def database_access_text(table)
    if table.enabled.to_s.blank?
      ''
    else
      table.enabled? ? 'Public' : 'Private'
    end
  end

end
