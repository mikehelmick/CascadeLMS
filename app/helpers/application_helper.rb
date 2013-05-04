require 'MyString'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def editor_rel
    return '' if @browser.android? || @browser.ios?
    return 'wysihtml5'
  end

  def format_autocomplete(items)
    sane_items = items.map { |i| i.format_autocomplete() }
    return "[\"#{items.join('", "')}\"]"
  end

  def error_class(object, field)
    begin
      if object.errors.invalid?(field)
        return 'error'
      end
    rescue
    end
    return ''
  end

  def error_help(object, field)
    begin
      if object.errors.invalid?(field)
        msg = ""
        object.errors[field].each do |err_msg|
          msg = "#{msg} <span class=\"help-inline\">#{err_msg}</span>"
        end
        return msg
      end
    rescue
    end
    return ''
  end
end
