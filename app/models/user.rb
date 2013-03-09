require 'digest/sha1'
require 'md5'

class User < ActiveRecord::Base
  validates_uniqueness_of :uniqueid, :message => 'That username is already taken.'
  validates_uniqueness_of :email, :message => 'That email address is already registered.'
  validates_presence_of :uniqueid, :password, :first_name, :last_name, :email
  validates_format_of :first_name, :last_name, :with => /^[a-zA-Z0-9 '-.][a-zA-Z0-9 '-.]*$/, :message => 'First and last name may only contains letters, numbers, "\'", spaces and "-" characters.'
  validates_length_of :uniqueid, :within => 4..99, :too_long => 'Your username must be less than 100 characters in length.', :too_short => 'Your username must be at least 4 characters in length.'
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  
  has_many :courses_users
  has_many :courses, :through => :courses_users
  
  has_many :course_shares
  
  has_many :programs_users
  has_many :programs, :through => :programs_users
  
  has_many :posts
  has_many :comments
  
  has_many :user_turnins, :dependent => :destroy
  has_many :journals, :dependent => :destroy
  
  has_many :grade_entries, :dependent => :destroy
  
  has_many :quiz_attempts, :dependent => :destroy
  
  has_many :rubric_entries, :dependent => :destroy
  
  has_many :notifications, :dependent => :destroy
  
  has_many :project_teams

  has_one :user_profile, :dependent => :destroy
  has_one :feed
  has_many :feed_subscriptions
  
  attr_accessor :notice

  def create_feed
    if self.feed.nil?
      self.feed = Feed.new
      self.feed.user_id = self.id
      self.feed.save
    end
    return self.feed
  end

  def notification_count
    Notification.count(:conditions => ["user_id = ? and acknowledged = ?", self.id, false])
  end
  
  def gravatar_url(ssl = false, size = 60)
    email_address = self.email.downcase
    #create the md5 hash
    hash = MD5::md5(email_address)
    
    return "http://www.gravatar.com/avatar/#{hash}.jpg?s=#{size}&d=wavatar&r=PG" unless ssl
    return "https://secure.gravatar.com/avatar/#{hash}.jpg?s=#{size}&d=wavatar&r=PG"
  end

  def assignment_journals( assignment )
    Journal.find(:all, :conditions => ["assignment_id = ? and user_id = ?", assignment.id, self.id], :order => 'created_at asc' )
  end
  
  def grade_for_grade_item( grade_item ) 
    GradeEntry.find(:first, :conditions => ["user_id = ? and grade_item_id =?", self.id, grade_item.id ] )
  end
  
  def display_name
    unless self.preferred_name.nil? || ''.eql?(self.preferred_name)
      "#{self.first_name} (#{self.preferred_name}) #{self.middle_name} #{self.last_name}"
    else
      "#{self.first_name} #{self.middle_name} #{self.last_name}"
    end
  end
  
  ## Returns a courses_user obj - so you have the course and relationship to the course
  def courses_in_term( term )
    cur = CoursesUser.find(:all, :conditions => ["user_id = ? and term_id =? and (course_student = ? or course_instructor = ? or course_guest = ? or course_assistant = ?)", self.id, term.id, true, true, true, true])
    cur.sort! do |x,y| 
      result = x.position <=> y.position
      result = x.course.title <=> y.course.title if result == 0
      result
    end    
  end

  def programs_under_audit() 
    prog_user = ProgramsUser.find(:all, :conditions => ["user_id = ? and program_auditor = ?", self.id, true])
    prog_user.sort! do |x,y|
      x.program.title <=> y.program.title
    end
  end

  def courses_instructing( term )
    all_term = courses_in_term( term )
    cur = Array.new
    all_term.each do |cu|
      cur << cu if cu.course.term_id == term.id && (cu.course_instructor || cu.course_instructor)
    end
    cur.sort! { |x,y| x.course.title <=> y.course.title }    
  end
  
  def courses_as_student_or_guest( term )
    all_term = courses_in_term( term )
    cur = Array.new
    all_term.each do |cu|
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
  
  def sharing_for_course?( course_id )
    return !course_share(course_id).nil?
  end
  
  def course_share( course_id ) 
    self.course_shares.each do |x|
      return x if x.course_id.to_i == course_id.to_i
    end
    nil
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
  
  def toggle_program_coordinator
    self.program_coordinator = !self.program_coordinator
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
      self.password = Digest::SHA1.hexdigest(email + "mmmm...salty" + new_password + "ROCK, ROCK ON")
      return true
    else 
      return false
    end
  end
  
  private :blank_in_course
  
end
