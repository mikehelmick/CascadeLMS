class Instructor::InstructorBase < ApplicationController
  
  def ensure_course_instructor( course, user )
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_instructor
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to perform that action."
    redirect_to :controller => '/overview', :course => course.id
    return false    
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
  
end