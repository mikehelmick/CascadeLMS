xml.instruct!
xml.rss "version" => "2.0", "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd" do
  xml.channel do
    xml.title "#{@folder.title} podcast - #{@course.title} (#{@course.term.semester}) - PUBLIC ACCESS"
	  xml.link url_for( :controller => '/public/documents', 
	                        :action => 'podcast', 
	                        :id => @folder.id, 
	                        :course => @course, 
	                        :only_path => false )
	  xml.pubDate CGI.rfc1123_date( @fresh_date )                     
	  xml.description("#{@folder.comments}")
	  xml.ttl "30"
	  
	
	  xml << "    <itunes:category text=\"Education\" />\n"
	
	  xml << "    <itunes:block>no</itunes:block>\n"
	  xml << "    <itunes:explicit>no</itunes:explicit>\n"
	  
	  xml << "    <language>en-us</language>\n"
	  
	  xml << "    <itunes:author>#{@course.instructors.join(', ')}</itunes:author>\n"
	  xml.itunes:owner do
      xml << "      <itunes:name>#{@course.instructors.join(', ')}</itunes:name>\n"
      
      emails = Array.new
      @course.instructors.each do |i|
        emails << i.email
      end
      xml << "      <itunes:email>#{emails.join(', ')}</itunes:email>\n"
    end
    xml << "    <itunes:summary>#{@folder.comments}</itunes:summary>\n"
    xml << "    <itunes:subtitle>#{@folder.comments}</itunes:subtitle>\n"
    
    @documents.each do |doc|
      xml.item do
        xml.title "#{doc.title}"
        xml.link url_for( :only_path => false,
  		                    :controller => '/public/documents',
  		                    :action => 'podcast_download',
  		                    :course => @course.id, 
  		                    :id => doc.id ,
  		                    :file => "file#{doc.id}",
                    		  :extension => "#{doc.extension}" )
  		  xml.guid url_for( :only_path => false,
                    		  :controller => '/public/documents',
                    		  :action => 'podcast_download',
                    		  :course => @course.id, 
                    		  :id => doc.id,
                    		  :file => "file#{doc.id}",
                    		  :extension => "#{doc.extension}" )
        xml.pubDate CGI.rfc1123_date( doc.created_at )
        xml.description "#{doc.comments} File Size: #{doc.size_text} File Type: #{doc.extension}"
        
        xml.enclosure( :url => url_for( :controller => '/public/documents', 
    	                        :action => 'podcast_download', 
    	                        :id => doc.id, 
    	                        :file => "file#{doc.id}",
                        		  :extension => "#{doc.extension}",
    	                        :course => @course, 
    	                        :only_path => false ), :length => "#{doc.size}", :type => "#{doc.content_type}" ) 
    	                        
    	  xml << "      <itunes:subtitle>#{doc.comments} File Size: #{doc.size_text} File Type: #{doc.extension}</itunes:subtitle>\n"
    	  xml << "      <itunes:summary>#{doc.comments} File Size: #{doc.size_text} File Type: #{doc.extension}</itunes:summary>\n"
        
        xml << "      <itunes:explicit>no</itunes:explicit>\n"
        
      end
    end

  end
end