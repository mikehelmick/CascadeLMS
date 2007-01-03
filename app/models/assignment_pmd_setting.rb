class AssignmentPmdSetting < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :style_check
  
  
end
