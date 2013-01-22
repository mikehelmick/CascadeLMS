xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1" do
  xml.channel do
    xml.title "#{@course.title} (#{@course.term.semester})"
	  xml.link_for url_for( :only_path => false,
	                        :controller => '/overview',
	                        :course => @course )
	  if @fresh_date.nil?
	    xml.putDate DateTime.now().new_offset(0)
  	else
	    xml.pubDate CGI.rfc1123_date(@fresh_date)
	  end
  	xml.description("Information about the course '#{@course.title}' (#{@course.term.semester}) at #{@app['organization']}")
	  @feed_items.each do |feed_item|
	    if feed_item.item.acl_check?(@user)
	      xml.item do
	        xml.title "#{feed_item.item.title}"
  	      xml.link url_for(:only_path => false,
	                         :controller => '/post',
	                         :action => 'view',
	                         id => feed_item.item.id)
	        xml.description feed_item.item.body_html
	        xml.pubDate CGI.rfc1123_date( feed_item.item.created_at )
	        xml.guid url_for(:only_path => false,
	                         :controller => '/post',
	                         :action => 'view',
	                         id => feed_item.item.id)
  	      xml.author h(feed_item.item.user.display_name)
  	    end
      end
    end
  end
end