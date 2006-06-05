class Assignment < ActiveRecord::Base
  belongs_to :course
  acts_as_list :scope => :presentation
  
  has_one :grade_category
  
  validates_presence_of :title
  # NEEDS extended validations
  # open < due <= close dates
  # either (1) description or (2) file uploads
  # if a SVN path is given, that is is appropriate 
  
end
