class FileStyle < ActiveRecord::Base
  belongs_to :user_turnin_file
  belongs_to :style_check
  
end
