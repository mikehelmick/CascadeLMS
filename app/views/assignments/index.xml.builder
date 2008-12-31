xml.instruct!
xml.assignments do
  @course.assignments.each do |assignment|
    xml.assignment do
      xml.id "#{assignment.id}"
      xml.title "#{assignment.title}"
      xml.category "#{assignment.grade_category.category}"
      
      xml.open_date CGI.rfc1123_date(assignment.open_date)
      xml.due_date CGI.rfc1123_date(assignment.due_date)
      xml.close_date CGI.rfc1123_date(assignment.close_date)
      
      xml.upcomming "#{assignment.upcoming?}"
      xml.current   "#{assignment.current?}"
      xml.past      "#{assignment.past?}"
      xml.closed    "#{assignment.closed?}"
      
      if !assignment.quiz.nil?
        xml.quiz "true"
      end
      
      if assignment.team_project
        xml.team_project "#{assignment.team_project}"
      end
      
      xml.grades_released "#{assignment.released}"
      
      if assignment.released && !assignment.grade_item.nil? 
        gi = @user.grade_for_grade_item(assignment.grade_item)
        if gi.nil? 
          xml.points_earned "no grade assigned"
          xml.points_possible "#{assignment.grade_item.points}"
        else
          xml.points_earned "#{gi.points}"
          xml.points_possible "#{assignment.grade_item.points}"
        end
      elsif !assignment.grade_item.nil? 
        xml.points_possible "#{assignment.grade_item.points}"
      end 
      
    end
  end
end