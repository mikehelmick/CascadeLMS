class Gradebook < ActiveRecord::Base
  set_primary_key 'course_id'
  belongs_to :course
  has_many :grade_weights, :dependent => :destroy
  
end
