class ForumTopic < ActiveRecord::Base
  
  belongs_to :course
  belongs_to :user
  acts_as_list :scope => :course
  has_many :forum_posts
  
  validates_presence_of :topic
  
  def change_time
    self.last_post = Time.now
  end
 
  
end
