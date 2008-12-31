xml.instruct!
xml.documents do
  @documents.each do |document|
    xml.document do
      xml.id "#{document.id}"
      xml.title "#{document.title}"
      xml.comments do
        xml.cdata! "#{document.comments_html}"
      end
      if document.folder
        xml.folder "#{document.folder}"
        if document.podcast_folder
          xml.podcast "#{document.podcast_folder}"
          xml.podcast_url url_for( :only_path => false,
        	                         :controller => '/documents',
        	                         :action => 'podcast',
        	                         :course => @course,
        	                         :id => document.id )
        end
      else
        xml.extension "#{document.extension}"
        xml.size "#{document.size}"
        xml.document_url url_for( :only_path => false,
      	                          :controller => '/documents',
      	                          :action => 'download',
      	                          :course => @course,
      	                          :id => document.id,
      	                          :file => document.without_extension, 
      	                          :extension => document.extension )
      end
      
    end
  end
end