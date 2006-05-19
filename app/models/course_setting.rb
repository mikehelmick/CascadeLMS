class CourseSetting < ActiveRecord::Base
  set_primary_key 'course_id'
  belongs_to :course
end
