module EntriesHelper

  def record_name(togodb_table, record)
    if togodb_table.record_name.blank?
      pkey_name = togodb_table.primary_column_internal_name
      rn = if pkey_name == 'id'
             if togodb_table.columns[0].respond_to?(:internal_name)
               record[togodb_table.columns[0].internal_name]
             else
               ''
             end
           else
             record[pkey_name]
           end
    else
      rn = togodb_table.record_name.gsub(/\{.+?\}/) { |s| record[Togodb::Column.name2internal_name(togodb_table.id, s[1 .. -2])] }
    end

    rn
  rescue
    ''
  end

  def set_page_setting(table)
    @page_setting = TogodbPage.find_by_table_id(table.id)
    #unless @page_setting
    #  @page_setting = Togodb::Page.create(:table_id => @db.id)
    #end

    @header_footer_lang = header_footer_lang(table)

    if @page_setting
      @header_line = @page_setting.header_line
      @multiple_language = multiple_language?(@page_setting, @header_footer_lang)
    else
      @header_line = false
      @multiple_language = false
    end
  end

  def header_footer_lang(db)
    lang = cookies[page_header_footer_lang_cookie_name(db)]
    if lang.blank?
      page = db.page
      if page
        lang = db.page.header_footer_lang
      end
    else
      lang = lang.to_i
    end

    lang
  end

  def page_header_footer_lang_cookie_name(table)
    "togodb-#{table.name}-header-footer-lang"
  end

  def multiple_language?(page_setting, header_footer_lang)
    header_footer_lang && header_footer_lang > 0 && page_setting.multiple_language
  end

  def show_embeded_elem_id(dbname)
    "togodb-#{dbname}-show"
  end

end
