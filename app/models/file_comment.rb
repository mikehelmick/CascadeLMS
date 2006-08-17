class FileComment < ActiveRecord::Base
  belongs_to :user_turnin_file
  belongs_to :user
  
end
