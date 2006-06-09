class UserTurninFile < ActiveRecord::Base
  belongs_to :user_turnin
  acts_as_list :scope => :user_turnin
  
  
end
