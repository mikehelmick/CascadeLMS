class Course < ActiveRecord::Base
  validates_presence_of :title
  
  belongs_to :term
  has_and_belongs_to_many :crns
  
  has_one :course_setting, :dependent => :destroy
  has_one :course_information, :dependent => :destroy
  has_one :gradebook, :dependent => :destroy
  has_many :grade_items, :order => "date", :dependent => :destroy
  
  has_many :documents, :order => "position", :dependent => :destroy
  has_many :assignments, :order => "position", :dependent => :destroy
  has_many :forum_topics, :order => "position", :dependent => :destroy
  
  has_many :courses_users
  has_many :users, :through => :courses_users
  has_many :posts, :order => "created_at", :dependent => :destroy
  
  has_many :journal_tasks, :dependent => :destroy
  has_many :journal_stop_reasons, :dependent => :destroy
  
  
  
  before_create :solidify
  
  def merge( other )
    Course.transaction do
      #puts "in a transaction?"
      
      # merge course details
      self.title = "#{self.title} #{other.title}"
      self.short_description = "#{self.short_description} #{other.short_description}"
      self.open = self.open || other.open
      
      # reassign any CRNs to this new course
      crnmap = Hash.new
      self.crns.each { |x| crnmap[x.crn] = true }
      
      other.crns.each do |x|
        unless crnmap[x.crn] 
          self.crns << Crn.find( x.id )
        end
      end
      other.crns.clear
      
      # Need to reassign users now - this is tricky...
      other.courses_users.each do |otheruser|
        added = false
        self.courses_users.each do |thisuser|
          if otheruser.user_id == thisuser.user_id 
            thisuser.course_student = thisuser.course_student || otheruser.course_student
            thisuser.course_instructor = thisuser.course_instructor || otheruser.course_instructor
            thisuser.course_guest = thisuser.course_guest || otheruser.course_guest
            thisuser.course_assistant = thisuser.course_assistant || otheruser.course_assistant
            thisuser.save
            added = true
          end  
        end  
        
        unless added
          courseuser = CoursesUser.new
          courseuser.user = otheruser.user
          courseuser.course = self
          courseuser.course_student = otheruser.course_student
          courseuser.course_instructor = otheruser.course_instructor
          courseuser.course_guest = otheruser.course_guest
          courseuser.course_assistant = otheruser.course_assistant
          
          courseuser.save
          self.courses_users << courseuser
        end
        
        # destroy the courses_user record - not the course or the user...
        otheruser.destroy
      end
      
      other.courses_users.clear
      other.save
      other.destroy
      
      self.save
    end
  end
  
  def open_text
    return 'Yes' if self.open
    return 'No'
  end
  
  def toggle_open
    self.open = ! self.open
  end
  
  def student_count
    count = 0
    self.courses_users.each { |u| count += 1 if u.course_student }
    count
  end
  
  def students
    inst = Array.new
    self.courses_users.each do |u|
      inst << u.user if u.course_student
    end
    sort_c_users inst
  end
  
  def assistants
    inst = Array.new
    self.courses_users.each do |u|
      inst << u.user if u.course_assistant
    end
    sort_c_users inst  
  end
  
  def guest_count
    count = 0
    self.courses_users.each { |u| count += 1 if u.course_guest }
    count
  end
  
  def guests
    inst = Array.new
    self.courses_users.each do |u|
      inst << u.user if u.course_guest
    end
    sort_c_users inst  
  end
  
  def instructors
    inst = Array.new
    self.courses_users.each do |u|
      inst << u.user if u.course_instructor
    end
    sort_c_users inst
  end
  
  def sort_c_users(arr)
    arr.sort! do |x,y|
      res = x.last_name.downcase <=> y.last_name.downcase
      if res == 0 
        res = x.uniqueid.downcase <=> y.uniqueid.downcase
      end
      res
    end
  end
  
  def solidify
    self.course_setting = CourseSetting.new if self.course_setting.nil?
  end
  
  private :sort_c_users
  
end
