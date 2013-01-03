require File.dirname(__FILE__) + '/../test_helper'

class ItemTest < ActiveSupport::TestCase
  fixtures :feeds, :items, :courses, :users, :courses_users, :feeds_items, :posts
  
  def test_share_with_user
    item = Item.find(1)
    user = User.find(3)

    item.share_with_user(user, Time.now())

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

  def test_add_to_recent_commenters
    item = Item.find(1)

    assert item.add_to_recent_commenters(User.find(1)).eql?('1')
    assert item.add_to_recent_commenters(User.find(2)).eql?('2,1')
    assert item.add_to_recent_commenters(User.find(1)).eql?('1,2')
  end

  def test_get_recent_commenters
    item = Item.find(1)

    assert item.get_recent_commenters().eql?([])
    item.add_to_recent_commenters(User.find(1))
    item.add_to_recent_commenters(User.find(2))
    item.add_to_recent_commenters(User.find(3))

    recent_users = item.get_recent_commenters()
    assert recent_users.size == 3
    assert recent_users[0].id == 3
    assert recent_users[1].id == 2
    assert recent_users[2].id == 1
  end

  def test_build_comment_message
    item = Item.find(1)

    item.add_to_recent_commenters(User.find(4))
    message = item.build_comment_message(item.get_recent_commenters(), User.find(1), item, 1, false)
    assert "Test (T.U.3) B. User commented on your post, Blog 'first'".eql?(message)

    item.add_to_recent_commenters(User.find(3))
    message = item.build_comment_message(item.get_recent_commenters(), User.find(1), item, 2, false)
    assert "Test (T.U.) A. User and Test (T.U.3) B. User commented on your post, Blog 'first'".eql?(message)
  end
end
