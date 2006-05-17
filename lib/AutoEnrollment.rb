require 'CourseCreator'
class AutoEnrollment < CourseCreator
  
  def initialize( user, crns, descs, format )
    super( user, crns, descs, format)
  end
  
  def reconcile
    
  end
  
end