xml.instruct!
xml.course_overview do
  xml.course do
    xml.id "#{@course.id}"
    xml.title "#{@course.title}"
    xml.short_description "#{@course.short_description}"
  end
  
  xml.recent do
    @recent_activity.each do |item|
      xml.item do
        xml.id "#{item.id}"
        xml.type "#{item.class.to_s}"
        xml.summary_date "#{item.summary_date}"
        xml.summary "#{item.summary_title}"
        
        if item.class.to_s.eql?("Assignment")
          xml.link_for url_for( :only_path => false,
        	                      :controller => '/assignments',
        	                      :action => 'view',
        	                      :course => @course,
        	                      :id => item.id )
        	                      
        elsif item.class.to_s.eql?("Document")
          xml.extension "#{item.extension}"
          xml.size "#{item.size}"
          xml.link_for url_for( :only_path => false,
        	                      :controller => '/documents',
        	                      :action => 'download',
        	                      :course => @course,
        	                      :id => item.id )
          
        elsif item.class.to_s.eql?("Comment")
          xml.link_for url_for( :only_path => false,
        	                      :controller => '/blog',
        	                      :action => 'post',
        	                      :course => @course,
        	                      :id => item.post_id )
        	                                
        elsif item.class.to_s.eql?("Post")
          xml.link_for url_for( :only_path => false,
        	                      :controller => '/blog',
        	                      :action => 'post',
        	                      :course => @course,
        	                      :id => item.id ) 
        end
      
      end
    end  
  end

end
