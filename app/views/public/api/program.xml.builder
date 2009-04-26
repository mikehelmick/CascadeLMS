xml.instruct!
xml.program do
  xml.title "#{@program.title}"
  xml.program_outcomes do
    @program.program_outcomes.each do |po|
      xml.outcome "#{po.outcome}"
    end
  end
  xml.courses do
    @program.course_templates.each do |course_template|
      if course_template.approved
        xml.course do
          xml.title "#{course_template.title}"
          xml.link url_for( :only_path => false,
        	                  :controller => '/public/api',
        	                  :action => 'course_templates',
        	                  :id => course_template )
        end
      end
    end
  end
end