xml.instruct!
xml.assignment_feedback do
  xml.id "#{@assignment.id}"
  xml.title "#{@assignment.title}"
  xml.category "#{@assignment.grade_category.category}"
  
  if @assignment.released && !@assignment.grade_item.nil? 
    gi = @user.grade_for_grade_item(@assignment.grade_item)
    if gi.nil? 
      xml.points_earned "no grade assigned"
      xml.points_possible "#{@assignment.grade_item.points}"
    else
      xml.points_earned "#{gi.points}"
      xml.points_possible "#{@assignment.grade_item.points}"
      xml.comments "#{gi.comment}"
    end
    
    xml.rubrics do
      @assignment.rubrics.each do |rubric|
        if rubric.visible_before_grade_release || (@assignment.released && rubric.visible_after_grade_release)
          xml.rubric do
            xml.primary_trait "#{rubric.primary_trait}"
            xml.no_credit_criteria "#{rubric.no_credit_criteria}"
            xml.no_credit_points "#{rubric.no_credit_points}"
            xml.part_credit_criteria "#{rubric.part_credit_criteria}"
            xml.part_credit_points "#{rubric.part_credit_points}"
            xml.full_credit_criteria "#{rubric.full_credit_criteria}"
            xml.full_credit_points "#{rubric.full_credit_points}"
            unless rubric.above_credit_criteria.nil?
              xml.above_credit_criteria "#{rubric.above_credit_criteria}"
              xml.above_credit_points "#{rubric.above_credit_points}"
            end

            xml.rubric_grade do
              if !@rubric_entry_map[rubric.id].nil?
                xml.no_credit_awarded "#{@rubric_entry_map[rubric.id].no_credit}"
                xml.partial_credit_awarded "#{@rubric_entry_map[rubric.id].partial_credit}"
                xml.full_credit_awarded "#{@rubric_entry_map[rubric.id].full_credit}"
                xml.above_credit_awarded "#{@rubric_entry_map[rubric.id].above_credit}"
              end
              xml.comments "#{@rubric_entry_map[rubric.id].comments}"
            end
          end
        end
      end
    end
    
  elsif !assignment.grade_item.nil? 
    xml.error "Grade is not yet available for this assignment."
  end
  
  
end