class Announcement < ActiveRecord::Base
  validates_presence_of :text
  
  has_one :user
  
  before_save :transform_markup
	
	def validate
    errors.add( 'start_time', 'must be before the end time.' ) unless self.end > self.start
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
		    self.text_html = HtmlEngine.apply_textile( self.text )
    end
end
