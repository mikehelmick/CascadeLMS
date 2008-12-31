xml.instruct!
xml.wiki_page do
  xml.page_name "#{@page.page}"
  xml.content do
    xml.cdata! "#{@page.content}"
  end
  xml.content_html do
    xml.cdata! "#{@page.content_html}"
  end
  xml.revision "#{@page.revision}"
  xml.last_author "#{@page.user.display_name}"
  xml.updated_at CGI.rfc1123_date(@page.updated_at)
end