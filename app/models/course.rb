class Course < ActiveRecord::Base
  validates_presence_of :title
  
  belongs_to :term
  has_and_belongs_to_many :crns
  
  has_one :course_setting, :dependent => :destroy
  has_one :course_twitter, :dependent => :destroy
  has_one :course_information, :dependent => :destroy
  has_one :gradebook, :dependent => :destroy
  has_one :rubric_level, :dependent => :destroy
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
  
  has_many :course_shares, :dependent => :destroy
  
  has_and_belongs_to_many :programs
  has_many :course_outcomes, :order => "position", :dependent => :destroy
  # rubrics are destroyed through the destruction of assignments
  has_many :rubrics
  
  has_one :feed
  
  before_create :solidify

  def create_feed
    if self.feed.nil?
      self.feed = Feed.new
      self.feed.user_id = self.id
      self.feed.save

      # TODO(helmick): Pre-populate the feed for legacy systems and courses.
    end
    return self.feed
  end

  def items_visible_to_user?(user)
    # Repeated calls will hit the query cache.
    cu_rec = CoursesUser.find(:first,
        :conditions => ["course_id = ? and user_id = ? and (course_student = ? or course_instructor = ? or course_guest = ? or course_assistant = ?)",
          self.id, user.id, true, true, true, true])
    return !cu_rec.nil?
  end
  
  def share_with_user(user)
    new_share = CourseShare.new
    new_share.course = self
    new_share.user = user
    new_share.save
    return new_share
  end

  def sorted_grade_items
    items = self.grade_items
    items.sort do |a,b|
      result = a.position <=> b.position
      result = a.date <=> b.date if result == 0
      result
    end
  end
  
  def mapped_to_program?( program_id )
    programs.each do |program|
      return true if program.id == program_id
    end
    return false
  end
  
  def merge( other, externalDir )
    Course.transaction do
      #puts "in a transaction?"
      
      # merge course details
      self.title = "#{self.title} #{other.title}"
      self.short_description = "#{self.short_description} #{other.short_description}"
      self.course_open = self.course_open || other.course_open
      
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
          courseuser.term_id = self.term_id
          
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
    
  def course_open_text
    return 'Yes' if self.course_open
    return 'No'
  end
  
  def toggle_open
    self.open = ! self.open
  end

  def wiki_page_count
    Wiki.count_by_sql("select count(distinct(page)) from wikis where course_id=#{self.id};")    
  end
  
  def student_count
    count = 0
    self.courses_users.each { |u| count += 1 if u.course_student }
    count
  end
  
  def students_courses_users
    inst = Array.new
    self.courses_users.each do |u|
      inst << u if u.course_student
    end
    sort_courses_users inst  
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

  def non_dropped_users
    users = Array.new
    self.courses_users.each do |u|
      users << u.user unless u.dropped
    end
    sort_c_users users
  end
  
  def drops
    users = Array.new
    self.courses_users.each do |u|
      users << u.user if u.dropped
    end
    sort_c_users users
  end

  def is_instructor(user_id)
    self.instructors.each do |i|
      return true if i.id == user_id
    end
    return false
  end
  
  def assignments_for_user( user_id )
    instructor = is_instructor(user_id)
    published_asgn = Array.new
    self.assignments.each do |asgn|
      published_asgn << asgn if asgn.visible || instructor
    end
    # if there are no project teams, you get all assignments
    return published_asgn unless self.course_setting.enable_project_teams
    # otherwise, we need to filter
    team_id = 0
    team = team_for_user(user_id)
    team_id = team.id unless team.nil?
    rtn_asgn = Array.new
    published_asgn.each do |asgn|
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
  
  def toggle_open 
    self.course_open = ! self.course_open
  end
  
  def extract_outcome_by_parent( outcomes, parent ) 
    #puts "EXTRACT: parent: #{parent}\n"  
    rtnArr = Array.new
    outcomes.each do |outcome|
      rtnArr << outcome if outcome.parent == parent
    end
    return rtnArr
  end

  ## May create a CRN, which does get saved down.
  def self.create_course(courseParams, termParams, crnParams, createNoneCrn)  
    course = Course.new(courseParams)
    term = Term.find(termParams)    
    course.term = term
    
    # if a CRN was provided...
    crn = Crn.find(:first, :conditions => ["crn = ?", crnParams] ) rescue crn = nil
    
    if crn
      course.crns << crn
      
    elsif !crnParams.nil? && !crnParams.eql?('')
      crn = Crn.new()
      crn.crn = crnParams
      crn.name = @course.title
      crn.save
      course.crns << crn
      
    elsif createNoneCrn
      begin
        course.crns << Crn.find(:first, :conditions => ["crn = ?", 'NONE'] ) 
      rescue
        crn = Crn.new
        crn.crn='NONE'
        crn.name='NONE'
        crn.title='NONE'
        crn.save
        course.crns << crn
      end
    end

    course.create_feed
    return course
  end
 
  private
  
  # sorts course_users entries
  def sort_courses_users(arr)
    arr.sort! do |x,y|
      res = x.crn_id <=> y.crn_id      
      if res != 0 && x.crn_id != 0 && y.crn_id != 0
        res = x.crn.name <=> y.crn.name
      end      
      if res == 0
        res = x.user.last_name.downcase <=> y.user.last_name.downcase
        if res == 0 
          res = x.user.uniqueid.downcase <=> y.user.uniqueid.downcase
        end
      end
      res
    end
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
  
  
end
