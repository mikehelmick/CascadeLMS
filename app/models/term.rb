class Term < ActiveRecord::Base
  validates_presence_of :term
  validates_presence_of :semester
  validates_presence_of :year
  
  has_many :courses
  
  def Term.find_current
    Term.find(:first, :conditions => ["current = ?", true], :order => ["term desc"] )
  end
  
end
