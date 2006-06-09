class UserTurnin < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user
  acts_as_list :scope => :user
  
  has_many :user_turnin_files, :order => "position asc", :dependent => "destroy"
  
end
