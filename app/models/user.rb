class User < ActiveRecord::Base
  validates_uniqueness_of :uniqueid
  validates_presence_of :uniqueid, :on => :create
  validates_presence_of :password
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :on => :create
  
  has_and_belongs_to_many :courses
  
  attr_accessor :notice
  
  def display_name
    unless self.preferred_name.nil?
      "#{self.preferred_name} #{self.last_name}"
    else
      "#{self.first_name} #{self.middle_name} #{self.last_name}"
    end
  end
  
  def toggle_instructor
    self.instructor = !self.instructor
  end
  
  def toggle_admin
    self.admin = !self.admin   
  end
  
  def valid_password?( password_entered )
    valid = Digest::SHA1.hexdigest( self.email + "mmmm...salty" + password_entered + "ROCK, ROCK ON" )
    return self.password.eql?(valid)
  end
  
  def before_create
    self.password = Digest::SHA1.hexdigest( self.email + "mmmm...salty" + self.password + "ROCK, ROCK ON" )
  end
  
  def to_s
    display_name
  end
  
  
end
