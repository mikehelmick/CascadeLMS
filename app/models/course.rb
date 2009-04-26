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
  
  has_many :class_periods, :order => "position", :dependent => :destroy
  
  has_many :project_teams, :order => "team_id", :dependent => :destroy
  
  has_and_belongs_to_many :programs
  has_many :course_outcomes, :order => "position", :dependent => :destroy
  # rubrics are destroyed through the destruction of assignments
  has_many :rubrics
  
  before_create :solidify
  
  def merge( other, externalDir )
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
      
      # Import Content - Blog posts first
      other.posts.each do |post|
        new_post = post.clone_to_course( self.id, post.user.id, 0 )
        self.posts << new_post
        self.save
      end
      # Import documents
      dir_created = false
      parent_map = Hash.new
      parent_map[0] = 0
      import_stack = Document.find(:all, :conditions => ["course_id = ? and document_parent = ?", other.id, 0], :order => "position DESC")
      # Process these as a stack
      while import_stack.size > 0
        copy_from = import_stack.pop
        new_doc = copy_from.clone_to_course( self.id, 0, 0 )
        new_doc.document_parent = parent_map[copy_from.document_parent]
        new_doc.save
        parent_map[copy_from.id] = new_doc.id
        
        # create dir
        new_doc.ensure_directory_exists(externalDir) unless dir_created
        dir_created = true
        
        ## If copy_from is a folder, load contents into stack
        if copy_from.folder
          contents = Document.find(:all, :conditions => ["course_id = ? and document_parent = ?", other.id, copy_from.id], :order => "position DESC")
          contents.each { |i| import_stack.push(i) }
        else
          ## Need to actually copy the file
          from_file_name = copy_from.resolve_file_name(externalDir)
          to_file_name = new_doc.resolve_file_name(externalDir)
          ## shell out to copy file
          `cp #{from_file_name} #{to_file_name}`
        end
      end
      # Import assignments
      other.assignments.each do |cp_asgn|
        new_asgn = cp_asgn.clone_to_course( self.id, 0, 0, externalDir )
        new_asgn.save
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
  
  def assignments_for_user( user_id )
    # if there are no project teams, you get all assignments
    return self.assignments unless self.course_setting.enable_project_teams
    # otherwise, we need to filter
    team_id = 0
    team = team_for_user(user_id)
    team_id = team.id unless team.nil?
    rtn_asgn = Array.new
    self.assignments.each do |asgn|
      rtn_asgn << asgn if asgn.enabled_for_team?(team_id)  
    end
    return rtn_asgn
  end
  
  def team_for_user( user_id )
    self.project_teams.each do |team|
      team.team_members.each do |tm|
        return team if tm.user_id == user_id
      end
    end
    return nil
  end
  
  def open_class_period?
    period = ClassPeriod.find(:first, :conditions => ["course_id = ? and open = ?", self.id, true] )
    return ! period.nil?
  end
  
  def solidify
    self.course_setting = CourseSetting.new if self.course_setting.nil?
  end
  
  def ordered_outcomes
    all_outcomes = self.course_outcomes
    
    ordered = add_outcomes_at_level( Array.new, all_outcomes, -1 )
      
    return ordered
  end
  
  def transative_program_outcomes
    pout_hash = Hash.new
    self.course_outcomes.each do |co|
      co.program_outcomes.each do |po|
        pout_hash[po.id] = po 
      end
    end
    return pout_hash
  end
  
  def add_outcomes_at_level( rtnArr, outcomes, parent ) 
    #puts "ADD parent: #{parent} \n    -----> #{rtnArr.inspect}\n"
    
    this_level_outcomes = extract_outcome_by_parent( outcomes, parent ).sort { |a,b| a.position <=> b.position }
    #puts "THIS LEVEL: #{this_level_outcomes.inspect}\n"
    this_level_outcomes.each do |outcome|
      rtnArr << outcome
      rtnArr = add_outcomes_at_level( rtnArr, outcomes, outcome.id )
    end   
    
    rtnArr
  end
  
  def extract_outcome_by_parent( outcomes, parent ) 
    #puts "EXTRACT: parent: #{parent}\n"  
    rtnArr = Array.new
    outcomes.each do |outcome|
      rtnArr << outcome if outcome.parent == parent
    end
    return rtnArr
  end
 
  private
  
  def sort_c_users(arr)
    arr.sort! do |x,y|
      res = x.last_name.downcase <=> y.last_name.downcase
      if res == 0 
        res = x.uniqueid.downcase <=> y.uniqueid.downcase
      end
      res
    end
  end
  
  
end
