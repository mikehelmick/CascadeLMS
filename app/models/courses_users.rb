class CoursesUsers < ActiveRecord::Base
  has_one :course
  has_one :user
end
