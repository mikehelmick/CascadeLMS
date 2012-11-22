class Item < ActiveRecord::Base
  has_many :feeds, :through => :feeds_items
  has_many :item_shares, :dependent => :destroy

  has_many :a_plus, :dependent => :destroy
  
  belongs_to :course
  belongs_to :user
  
  belongs_to :assignment
  belongs_to :post
  belongs_to :document
  belongs_to :wiki
  belongs_to :forum_post
  
  before_save :transform_markup
  
  def forum?
    return !self.forum_post_id.nil? && self.forum_post_id > 0
  end

  # Toggle the A+ status for an item/user pair.
  # This is done in a transaction, using locking on the item.
  #
  # Returns a pair of:
  #   updated item (w/ new count), APlus record for user (or nil)
  def self.toggle_plus(item, user)
    nitem = nil
    aplus = nil
    
    Item.transaction do
      uncached do
        nitem = Item.find(item.id, :lock => true)
        aplus = APlus.find(:first, :conditions => ["item_id = ? and user_id =?", item.id, user.id], :lock => true)

        if aplus.nil?
          aplus = APlus.for(item, user)
          nitem.aplus_count = nitem.aplus_count + 1
        else
          APlus.delete_all(["item_id = ? and user_id =?", item.id, user.id])
          aplus = nil
          nitem.aplus_count = nitem.aplus_count - 1
          # sanity check condition
          nitem.aplus_count = 0 if nitem.aplus_count < 0
        end
        
        # Save everything back, commit
        nitem.save
      end
    end

    return nitem, aplus
  end

  # Share this item with a whole course.
  def share_with_course(course, timestamp)
    ItemShare.for_course(self, course)
    publish_to_course(course, timestamp)
  end
  
  # Share with a specific user only.
  def share_with_user(user, timestamp)
    ItemShare.for_user(self, user)
    publish_to_user(user, timestamp)
  end

  # Check if an individual user did an A+ operation
  def user_aplus?(user)
    return !APlus.find(:first, :conditions => ["item_id = ? and user_id =?", self.id, user.id]).nil?
  end
  
  def transform_markup
	  this_post = self.body
	  this_post = this_post.apply_code_tag
	  this_post = this_post.apply_quote_tag
	  
	  self.body_html = HtmlEngine.apply_textile(this_post)
  end
  
  protected :transform_markup

  private
  def publish_to_course(course, timestamp)
    # publish to the course's feed
    feed = course.create_feed
    FeedsItems.create(feed.id, self.id, timestamp)

    # publish to the subscribers
    feed.feed_subscriptions.each do |fs|
      publish_to_user(fs.user, timestamp)
    end
  end

  def publish_to_user(user, timestamp)
    # We need to put this item in the target user's feed
    user_feed_id = user.create_feed.id
    FeedsItems.create(user_feed_id, self.id, timestamp)
  end
end
