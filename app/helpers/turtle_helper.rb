module TurtleHelper

  def button_area
    mapping_updated = @work.mapping_updated || Time.now
    last_generation_date = TurtleGeneration.last_generation_date(@work.id)
    dl_button_label = 'Download turtle'

    update_button_label = if last_generation_date
                            if @turtle_exist
                              'Update turtle'
                            else
                              'Generate turtle'
                            end
                          else
                            # No turtle
                            'Generate turtle'
                          end

    active_button = @turtle_exist && @turtle_is_latest ? 'download' : 'update'

    case active_button
    when 'download'
      dl_button_class = 'btn btn-primary'
      dl_button_style = nil
      dl_button_disabled = nil
      update_button_class = 'btn btn-default'
      update_button_style = 'cursor: default'
      update_button_disabled = 'disabled'
    when 'update'
      dl_button_class = 'btn btn-default'
      dl_button_style = 'cursor: default'
      dl_button_disabled = 'disabled'
      update_button_class = 'btn btn-primary'
      update_button_style = nil
      update_button_disabled = nil
    end

    dl_button_html =
        button_tag(type: 'button', id: 'd2rq-dumped-turtle-dl-btn', class: dl_button_class, style: dl_button_style, disabled: dl_button_disabled) do
          content_tag('i', '', class: 'fa fa-download') + dl_button_label
        end
    update_button_html =
        button_tag(type: 'button', id: 'd2rq-turtle-generate-btn', class: update_button_class, style: update_button_style, disabled: update_button_disabled) do
          content_tag('i', '', class: 'fa fa-file-text-o') + update_button_label
        end

    buttons = []
    case active_button
    when 'download'
      buttons << link_to(download_turtle_path) do
        dl_button_html
      end
      buttons << update_button_html
    when 'update'
      buttons << dl_button_html
      buttons << link_to(generate_turtle_path, data: { remote: true }) do
        update_button_html
      end
    end

    buttons.join(' ')
  end

end
