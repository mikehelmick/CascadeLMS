xml.instruct!
xml.wiki_index do
  @pages.each do |page|
    xml.page do
      xml.page_name "#{page.page}"
      xml.revision "#{page.revision}"
      xml.last_author "#{page.user.display_name}"
      xml.updated_at CGI.rfc1123_date(page.updated_at)
    end
  end  
end