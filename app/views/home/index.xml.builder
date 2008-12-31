xml.instruct!
xml.home do
  xml.announcements do
    @announcements.each do |i|
      xml.announcement do
        xml.id "#{i.id}"
        xml.headline "#{i.headline}"
        xml.text "#{i.text}"
        xml.start CGI.rfc1123_date(i.start)
        xml.end CGI.rfc1123_date(i.end)
      end
    end
  end
  
  xml.current_courses do
    @courses.each do |cuser|
      xml.course do
        xml.id "#{cuser.course.id}"
        xml.title "#{cuser.course.title}"
        xml.short_description "#{cuser.course.short_description}"
      end
    end
  end
  
  xml.past_courses do
    @other_courses.each do |course|
      xml.past_course do 
        xml.id "#{course.id}"
        xml.title "#{course.title}"
        xml.short_description "#{course.short_description}"
      end
    end
  end
end # overall end