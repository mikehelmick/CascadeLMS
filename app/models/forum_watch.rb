class ForumWatch < ActiveRecord::Base
  
  belongs_to :forum_topic
  belongs_to :user
  
end
