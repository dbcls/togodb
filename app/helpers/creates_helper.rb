module CreatesHelper

  def create_page_title
    case @create.mode
    when 'create'
      'Create database'
    when 'append'
      'Add data to the database'
    end
  end
end
