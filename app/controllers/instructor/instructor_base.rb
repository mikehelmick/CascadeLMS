class Instructor::InstructorBase < ApplicationController
  
  def assignment_in_course( course, assignment )
    unless course.id == assignment.course.id
      redirect_to :controller => '/instructor/index', :course => course
      flash[:notice] = "Requested assignment could not be found."
      return false
    end
    true
  end
  
  def document_in_assignment( document, assignment )
    unless document.assignment.id == assignment.id
      redirect_to :controller => '/instructor/course_assignments', :action => 'edit', :id => assignment.id, :course => @course
      flash[:notice] = "Requested document could not be found."
      return false
    end
    true   
  end
  
  def process_file( file_param, supress_error = false )
    # see if we got a document
    if file_param && file_param.size > 0
      if file_param.nil? || file_param.class.to_s.eql?('String')
        flash[:badnotice] = "You must upload an assignment file, or enter a description.  All filenames must have an extension, but may only contain a single period ('.') character." unless supress_error
        return true
      else
        @asgm_document = AssignmentDocument.new
        @asgm_document.set_file_props( file_param )
        @assignment.assignment_documents << @asgm_document
        @assignment.file_uploads = true
        return false
      end
    end
  end 
  
  def assignment_uses_autograde( course, assignment )
     unless assignment.auto_grade
        redirect_to :action => 'index', :course => course
        flash[:notice] = "The selected assignment does not have AutoGrade enabled."
        return false
      end
      true    
  end
  
  def assignment_uses_pmd( course, assignment )
    return false if assignment.auto_grade_setting.nil?
    unless assignment.auto_grade_setting.student_style || assignment.auto_grade_setting.style
      redirect_to :action => 'index', :course => course
      flash[:notice] = "The selected assignment does not have PMD style checking enabled."
      return false
    end
    return true
  end
  
  def assignment_uses_io_autograde( course, assignment )
    return false if assignment.auto_grade_setting.nil?
    unless assignment.auto_grade_setting.student_io_check || assignment.auto_grade_setting.io_check
      redirect_to :controller => '/instructor/course_assignments', :action => 'autograde', :course => course, :id => assignment
      flash[:notice] = "The selected assignment does not have input/output automatic grading enabled."
      return false
    end
    return true    
  end

  def ensure_course_assistant( course, user )
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_assistant
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to perform that action."
    redirect_to :controller => '/overview', :course => course.id
    return false    
  end
  
  def ensure_course_instructor_on_assistant( course, user )
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_instructor || cu.course_assistant
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to perform that action."
    redirect_to :controller => '/overview', :course => course.id
    return false
  end
  
  def quiz_enabled( course )
    unless course.course_setting.enable_quizzes
      flash[:badnotice] = "Quizzes are not enabled for this course."
      redirect_to :controller => '/instructor/index', :course => course
      return false
    end
    return true
  end
  
  def assignment_is_quiz( assignment )
    unless assignment.is_quiz?
      flash[:badnotice] = "Assignment is not a quiz."
      redirect_to :controller => '/instructor/course_assignments', :course => @course
      return false      
    end
    return true
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
end