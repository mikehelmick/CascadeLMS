xml.instruct!
xml.grades do
  @grade_items.each do |grade_item|
    if grade_item.visible
    xml.grade do
      if grade_item.assignment_id && grade_item.assignment_id > 0
        xml.assignment_id "#{grade_item.assignment.id}"
      else
        xml.assignment_id "-1"
      end
      xml.assignment "#{grade_item.name}"
      
      xml.category "#{grade_item.grade_category.category}"
      
      if  @course.gradebook && @course.gradebook.weight_grades 
        xml.category_weight "#{sprintf("%.2f", @weight_map[grade_item.grade_category.id] )}"
      end
      
      xml.date CGI.rfc1123_date(grade_item.date.to_time)
      
      if grade_item.display_type.eql?( GradeItem::shown_type( GradeItem::COMPLETE ) ) 
        xml.grade_type "Complete/Incomplete"
  		  if @grade_map[grade_item.id].nil? 
  		    xml.grade "Incomplete"
  			else
  			  xml.grade "Complete"
  			end
  		
  		elsif grade_item.display_type.eql?( GradeItem::shown_type( GradeItem::PERCENTAGE ) )
  		  xml.grade_type "Percentage"
  			unless @grade_map[grade_item.id].nil? 
  	      xml.grade "#{sprintf( "%.2f",  @grade_map[grade_item.id] / grade_item.points * 100 )}"
  	    else
  	      xml.grade "--"
  	    end
      
      else 
        xml.grade_type "Score"
        if @grade_map[grade_item.id].nil? 
          xml.grade "No Grade Reported"
        else
          xml.grade "#{sprintf("%.1f", @grade_map[grade_item.id].to_f )}"
        end
        
        xml.points_possible "#{grade_item.points}"
        unless @grade_map[grade_item.id].nil? 
          xml.percentage "#{sprintf( "%.2f",  @grade_map[grade_item.id] / grade_item.points * 100 )}"
        else 
          xml.percentage "--"
        end
      end
    
    end
    end
  end
end


#  <th>Feedback</th>
#  <th>Category</th>
#  <% if !@course.gradebook.nil? && @course.gradebook.weight_grades %><th>Category Weight</th><% end %>
#  <th>Date</th>
#  <th>Your Score</th>
#  <th>Possible Points</th>
#  <th>Percentage</th>