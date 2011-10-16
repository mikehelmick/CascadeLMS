require File.dirname(__FILE__) + '/../test_helper'

class ItemTest < ActiveSupport::TestCase
  fixtures :feeds, :items, :courses, :users, :courses_users, :feeds_items
  
  def test_share_with_user
    item = Item.find(1)
    user = User.find(3)

    item.share_with_user(user)

    # Assert that we can find the appropriate publishing information
    # An item share that can be used to re-evaluate ACLs at later date
    assert !ItemShare.find(:first, :conditions => ["item_id = ? and user_id = ?", 1, 3]).nil?
    # This item added to the user's feed
    assert !FeedsItems.find(:first, :conditions => ["item_id = ? and feed_id = ?", 1, user.feed.id]).nil?

    # Items in the feed
    items = user.feed.load_items
    assert items.size == 1
    assert item.id == items[0].item.id
  end

  def test_share_with_course
    
  end
end
