require File.dirname(__FILE__) + '/../test_helper'

class AnnouncementTest < ActiveSupport::TestCase
  fixtures :announcements

  def test_future
    announcement = Announcement.new
    announcement.start = Time.now + 100
    announcement.end = announcement.start + 1
    
    assert announcement.future?
    assert !announcement.current?
  end

  def test_validate
    announcement = Announcement.new
    announcement.start = Time.now + 100
    announcement.end = announcement.start - 500
    
    assert !announcement.valid?
    assert announcement.errors.invalid?(:start)
    assert_equal Announcement::INVALID_START_TIME_MSG, announcement.errors.on(:start)
  end
  
  def test_current_announcements
    current = Announcement.current_announcements
    
    assert current.size == 1
    assert current[0].id == 2
    assert current[0].headline.eql?("Current")
    assert current[0].current?
  end

  def test_future_form_db
    future = Announcement.find(3)
    
    assert future.future?
    assert !future.current?
  end

  def test_transform_markup
    # nothing too fancy, external library does transformations.
    announcement = Announcement.new
    
    announcement.text = "Hello *world*."
    announcement.start = Time.now
    announcement.end = Time.now
    announcement.save
    
    assert announcement.text_html = "<p>Hello <strong>world</strong>.</p>"
  end
end
