Jbuilder.encode do |json|
  json.assignments @assignments do |assignment|
    json.id assignment.id
    json.title "#{assignment.title}"
    json.category "#{assignment.grade_category.category}"

    json.open_date CGI.rfc1123_date(assignment.open_date)
    json.due_date CGI.rfc1123_date(assignment.due_date)
    json.close_date CGI.rfc1123_date(assignment.close_date)

    json.upcoming  assignment.upcoming?
    json.current   assignment.current?
    json.past      assignment.past?
    json.closed    assignment.closed?

    if !assignment.quiz.nil?
      json.quiz true
    end

    if assignment.team_project
      json.team_project "#{assignment.team_project}"
    end

    json.grades_released assignment.released

    if assignment.released && !assignment.grade_item.nil?
      gi = @user.grade_for_grade_item(assignment.grade_item)
      if gi.nil?
        json.points_earned "no grade assigned"
        json.points_possible assignment.grade_item.points
      else
        json.points_earned gi.points
        json.points_possible assignment.grade_item.points
      end
    elsif !assignment.grade_item.nil?
      json.points_possible assignment.grade_item.points
    end

  end
end # overall end