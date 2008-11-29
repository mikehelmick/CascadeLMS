class CoursesPrograms < ActiveRecord::Base
  
  belongs_to :course
  belongs_to :program
  
  def to_s
    "#{course.to_s} <-> #{program.to_s}"
  end
  
end
