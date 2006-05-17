class Crn < ActiveRecord::Base
  validates_presence_of :crn, :name
  validates_uniqueness_of :crn
  
  has_and_belongs_to_many :courses
  
  def to_s
    self.crn
  end
  
end
