require 'digest/sha1'

class User < ActiveRecord::Base
  validates_uniqueness_of :uniqueid
  validates_presence_of :uniqueid, :password, :first_name, :last_name, :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :on => :create
  
  has_many :courses_users
  has_many :courses, :through => :courses_users
  
  has_many :programs_users
  has_many :programs, :through => :programs_users
  
  has_many :posts
  has_many :comments
  
  has_many :user_turnins, :dependent => :destroy
  has_many :journals, :dependent => :destroy
  
  has_many :grade_entries, :dependent => :destroy
  
  has_many :project_teams
  
  attr_accessor :notice
  
  def assignment_journals( assignment )
    Journal.find(:all, :conditions => ["assignment_id = ? and user_id = ?", assignment.id, self.id], :order => 'created_at asc' )
  end
  
  def grade_for_grade_item( grade_item ) 
    GradeEntry.find(:first, :conditions => ["user_id = ? and grade_item_id =?", self.id, grade_item.id ] )
  end
  
  def display_name
    unless self.preferred_name.nil?
      "#{self.first_name} (#{self.preferred_name}) #{self.middle_name} #{self.last_name}"
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
  
  def assistant_in_course_with_privilege?( course_id, privilege )
    if blank_in_course( course_id ) { |x| x.course_assistant }
       setting = CourseSetting.find( course_id )
       return setting.ta_course_blog_edit
     end
     return false
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
  
  def program_manager?
    self.programs_users.each do |x|
      if x.program_manager
        return true
      end
    end
    false
  end
  
  def manager_in_program?( program_id )  
    blank_in_program( program_id ) { |x| x.program_manager }
  end
  
  def auditor_in_program?( program_id )
    blank_in_program( program_id ) { |x| x.program_auditor }
  end
  
  def blank_in_program( program_id, &cb ) 
    self.programs_users.each do |x|
      if x.program_id.to_i == program_id.to_i
        return cb.call( x )
      end
    end
    false
  end
  
  def toggle_instructor
    self.instructor = !self.instructor
  end
  
  def toggle_auditor
    self.auditor = !self.auditor   
  end
  
  def toggle_admin
    self.admin = !self.admin   
  end
  
  def toggle_enabled
    self.enabled = !self.enabled
  end
  
  def valid_password?( password_entered )
    valid = Digest::SHA1.hexdigest( self.email + "mmmm...salty" + password_entered + "ROCK, ROCK ON" )
    return self.password.eql?(valid)
  end
  
  def update_password( new_password ) 
    self.password = Digest::SHA1.hexdigest( self.email + "mmmm...salty" + new_password + "ROCK, ROCK ON" )
  end
  
  def before_create
    self.password = Digest::SHA1.hexdigest( self.email + "mmmm...salty" + self.password + "ROCK, ROCK ON" )
  end
  
  def User.gen_token( size = 48 )
    letters = ('a'..'z').to_a
    (0..9).to_a.each { |i| letters << i }
    
    tok = ''
    1.upto(size) do |x| 
      idx = rand(letters.size)
      tok = "#{tok}#{letters[idx]}"
    end
    return tok
  end
  
  def to_s
    display_name
  end
  
  def change_email( email, new_password ) 
    if valid_password?( new_password )
      self.email = email
      self.password = Digest::SHA1.hexdigest( self.email + "mmmm...salty" + new_password + "ROCK, ROCK ON" )
      return true
    else 
      return false
    end
  end
  
  private :blank_in_course
  
end
