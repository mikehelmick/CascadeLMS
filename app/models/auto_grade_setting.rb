class AutoGradeSetting < ActiveRecord::Base
  set_primary_key 'assignment_id'
  belongs_to :assignment
  
  def check_style?
    self.style || self.student_style
  end
  
  def io_check?
    self.io_check || self.student_io_check
  end
  
  def any_student_grade?
    self.student_style || self.student_io_check || self.student_autograde
  end
  
end
