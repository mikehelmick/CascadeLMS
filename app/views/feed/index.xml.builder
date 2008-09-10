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
	@recent_activity.each do |recent|
		xml.item do
		  xml.title "#{recent.feed_action}: #{recent.summary_title}"
		  xml.link url_for( :only_path => false,
		                    :controller => '/redirect',
		                    :type => "#{recent.class.to_s}", 
		                    :id => recent.id )
		  
		  if recent.class.to_s.eql?("Assignment") || recent.class.to_s.eql?("Document")
			xml.description url_for( :only_path => false,
			                    :controller => '/redirect',
			                    :type => "#{recent.class.to_s}", 
			                    :id => recent.id )
		  else
		    xml.description recent.body_html
		  end
		 
		  if recent.class.to_s.eql?("Assignment")
		  	xml.pubDate CGI.rfc1123_date( recent.open_date )
		  else
		    xml.pubDate CGI.rfc1123_date( recent.created_at )
		  end
		  xml.guid url_for( :only_path => false,
		                    :controller => '/redirect',
		                    :type => "#{recent.class.to_s}", 
		                    :id => recent.id )
		  if recent.class.to_s.eql?("Assignment") || recent.class.to_s.eql?("Document")
		    xml.author h(@course.instructors.join(', '))
		  else
		    xml.author h(recent.summary_actor)
		  end
		end
	end
  end
end