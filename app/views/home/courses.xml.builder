xml.instruct!
xml.courses do
  @courses.each do |course|
    xml.course do
      xml.id course.id
      xml.term do 
        xml.id course.term.id
        xml.term course.term.term
        xml.semester course.term.semester
        xml.current course.term.current
      end
      xml.title course.title
      xml.description course.short_description
    end
  end
end