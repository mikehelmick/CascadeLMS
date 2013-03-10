class Announcement < ActiveRecord::Base
  INVALID_START_TIME_MSG = 'must be before the end time.'
  
  validates_presence_of :text
  
  has_one :user
  
  before_save :transform_markup
	
	def validate
    errors.add( :start, INVALID_START_TIME_MSG) unless self.end > self.start
  end
	
	def future?
	  today = Time.now
	  self.start > today
  end
	
	def current?
	  today = Time.now
	  self.end >= today && self.start <= today
  end
  
  def Announcement.current_announcements
    today = Time.now
    Announcement.find(:all, :conditions => ["start <= ? and end >=?", today, today ], :order => "start desc")
  end
	
	protected
		
		def transform_markup
		    self.text_html = self.text.apply_markup()
    end
end
