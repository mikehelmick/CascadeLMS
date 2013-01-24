require 'MyString'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def format_autocomplete(items)
    sane_items = items.map { |i| i.format_autocomplete() }
    return "[\"#{items.join('", "')}\"]"
  end
end
