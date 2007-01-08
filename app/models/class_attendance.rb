class ClassAttendance < ActiveRecord::Base
  
  belongs_to :class_period
  belongs_to :user
  belongs_to :course
  
end
