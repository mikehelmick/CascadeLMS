class ClassPeriod < ActiveRecord::Base
  belongs_to :course
  acts_as_list :scope => :course
  
  belongs_to :user
  
  has_many :class_attendances
  
  
  def before_create
    self.key = Digest::SHA1.hexdigest( "attendance key #{Time.new.to_formatted_s(:long)}" )[0...6].upcase
  end
  
  
end
