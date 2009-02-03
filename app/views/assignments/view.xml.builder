xml.instruct!
xml.assignment do
  xml.id "#{@assignment.id}"
  xml.title "#{@assignment.title}"
  xml.category "#{@assignment.grade_category.category}"
  
  xml.open_date CGI.rfc1123_date(@assignment.open_date)
  xml.due_date CGI.rfc1123_date(@assignment.due_date)
  xml.close_date CGI.rfc1123_date(@assignment.close_date)
  
  xml.upcomming "#{@assignment.upcoming?}"
  xml.current   "#{@assignment.current?}"
  xml.past      "#{@assignment.past?}"
  xml.closed    "#{@assignment.closed?}"
  
  if !@assignment.quiz.nil?
    xml.quiz "true"
  end
  
  if @assignment.team_project
    xml.team_project "#{@assignment.team_project}"
  end
  
  xml.grades_released "#{@assignment.released}"
  
  if @assignment.released && !@assignment.grade_item.nil? 
    gi = @user.grade_for_grade_item(@assignment.grade_item)
    if gi.nil? 
      xml.points_earned "no grade assigned"
      xml.points_possible "#{@assignment.grade_item.points}"
    else
      xml.points_earned "#{gi.points}"
      xml.points_possible "#{@assignment.grade_item.points}"
    end
  elsif !assignment.grade_item.nil? 
    xml.points_possible "#{@assignment.grade_item.points}"
  end
  
  
  if @assignment.file_uploads 
    xml.attachments do
      @assignment.assignment_documents.each do |asgn_doc|
	      xml.attachment do
	        xml.filename "#{asgn_doc.filename}"
	        xml.size "#{asgn_doc.size_text}"
	        xml.document_url url_for( :only_path => false,
      	                            :controller => '/assignments',
      	                            :action => 'download',
      	                            :course => @course,
      	                            :id => @assignment.id,
      	                            :document => asgn_doc.id,
      	                            :file => asgn_doc.without_extension, 
      	                            :extension => asgn_doc.extension )
        end
	    end
    end
  else  
    unless @assignment.description.nil? or @assignment.description.size == 0
      xml.description do
        xml.cdata! "#{@assignment.description_html}"
      end
    end
  end
  
  turnin_methods = Array.new
  if (@assignment.use_subversion && @assignment.programming) && @assignment.enable_upload 
    turnin_methods << "Subversion" 
    turnin_methods << "Upload"
  elsif @assignment.use_subversion && @assignment.programming
    turnin_methods << "Subversion"
  elsif @assignment.enable_upload 
    turnin_methods << "Upload"
  else
    turnin_methods << "Printout" 
  end
  xml.turnin_methods do
    turnin_methods.each do |method|
      xml.method "#{method}"
    end
  end
  
  xml.journals_required "#{@assignment.enable_journal}"
  
  if @assignment.programming 
    xml.auto_grade_enabled "#{@assignment.auto_grade}"
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
          xml.above_credit_criteria "#{rubric.above_credit_criteria}"
          xml.above_credit_points "#{rubric.above_credit_points}"
          
          if rubric.course_outcomes.size > 0
            xml.course_outcomes do
              rubric.course_outcomes.each do |co|
                xml.outcome do
                  xml.number "#{@numbers[co.id]}"
                  xml.outcome "#{co.outcome}"
                end
              end
            end
          end
        end
      end
    end
  end
  
  
  
end