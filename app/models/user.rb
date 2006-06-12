class User < ActiveRecord::Base
  validates_uniqueness_of :uniqueid
  validates_presence_of :uniqueid, :on => :create
  validates_presence_of :password
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :on => :create
  
  has_many :courses_users
  has_many :courses, :through => :courses_users
  
  has_many :posts
  has_many :comments
  
  has_many :user_turnins, :order => "assignment_id asc, position desc", :dependent => :destroy
  
  
  attr_accessor :notice
  
  def display_name
    unless self.preferred_name.nil?
      "#{self.preferred_name} #{self.last_name}"
    else
      "#{self.first_name} #{self.middle_name} #{self.last_name}"
    end
  end
  
  def courses_in_term( term )
    cur = Array.new
    courses_users.each do |cu|
      cur << cu if cu.course.term_id == term.id && cu.course
    end
    cur.sort! { |x,y| x.course.title <=> y.course.title }    
  end

  def courses_instructing( term )
    cur = Array.new
    courses_users.each do |cu|
      cur << cu if cu.course.term_id == term.id && (cu.course_instructor || cu.course_instructor)
    end
    cur.sort! { |x,y| x.course.title <=> y.course.title }    
  end
  
  def courses_as_student_or_guest( term )
    cur = Array.new
    courses_users.each do |cu|
      cur << cu if cu.course.term.id == term.id && (cu.course_student || cu.course_guest)
    end
    cur.sort! { |x,y| x.course.title <=> y.course.title }
  end
  
  def student_in_course?( course_id )
    blank_in_course( course_id ) { |x| x.course_student }
  end
  
  def assistant_in_course?( course_id )
    blank_in_course( course_id ) { |x| x.course_assistant }
  end
  
  def guest_in_course?( course_id )
    blank_in_course( course_id ) { |x| x.course_guest }
  end
  
  def instructor_in_course?( course_id )
    blank_in_course( course_id ) { |x| x.course_instructor }
  end
  
  def blank_in_course( course_id, &cb ) 
    self.courses_users.each do |x|
      if x.course_id.to_i == course_id.to_i
        #puts "#{x.inspect}\n --- #{cb.call(x)} \n\n"
        return cb.call( x )
      end
    end
    false
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
  
  private :blank_in_course
  
end
