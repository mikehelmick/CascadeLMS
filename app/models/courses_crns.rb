class CoursesCrns < ActiveRecord::Base
  has_one :course
  has_one :crn
end
