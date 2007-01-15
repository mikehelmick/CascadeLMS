class IoCheckResult < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :user_turnin
  belongs_to :io_check
  
end
