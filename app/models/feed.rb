require 'action_controller'

class Feed < ActiveRecord::Base

  has_many :items, :through => :feeds_items
  
  has_many :feed_subscriptions

  # Gets one page of items for this feed
  def load_items(limit = 25, page = 1)
    pages = ActionController::Base::Paginator.new(self, FeedsItems.count(:conditions => ["feed_id = ?", self.id]), limit, page)
    items = FeedsItems.find(:all, :conditions => ['feed_id = ?', self.id], :order => 'timestamp DESC, item_id DESC', :limit => limit, :offset => pages.current.offset)
    return items
  end
  
  def validate
    # Ensure that a feed is only for a course, or only for a user, not both or neither.
    if self.user_id.nil? && self.course_id.nil?
      errors.add_to_base( 'A feed must be assoficated with a user or a course.' )
    elsif self.user_id.nil? == self.course_id.nil?
      errors.add_to_base( 'A feed can only be for a course or a user' )
    end
  end  
end
