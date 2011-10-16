require File.dirname(__FILE__) + '/../test_helper'

class FeedTest < ActiveSupport::TestCase
  fixtures :feeds, :items, :courses, :users, :courses_users, :feeds_items

  def test_user_feed_read
    feed = Feed.find(1)
    assert feed.user_id == 1
  end

  def test_user_feed_paginate
    item1 = Item.find(1)
    item2 = Item.find(2)
    user = User.find(3)

    item1.share_with_user(user)
    item2.share_with_user(user)

    # check feed pagination
    page1 = user.feed.load_items(1,1) # 1 item per page, page 0
    assert page1.size == 1
    assert page1[0].item_id == item2.id # shared later

    page2 = user.feed.load_items(1,2) # 1 item per page, page 1
    assert page2.size == 1
    assert page2[0].item_id == item1.id

    # get them both on 1 page
    allPosts = user.feed.load_items(5)
    assert allPosts.size == 2
    assert allPosts[0].item_id == item2.id
    assert allPosts[1].item_id == item1.id
  end
end
