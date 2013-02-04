class Assignment < ActiveRecord::Base
  belongs_to :course
  acts_as_list :scope => :course
  
  belongs_to :grade_category
  belongs_to :user
  has_one :journal_field, :dependent => :destroy
  
  has_many :assignment_documents, :order => "position", :dependent => :destroy
  has_many :user_turnins, :order => "user_id asc, position desc", :dependent => :destroy
  
  has_many :journals, :dependent => :destroy
  
  has_many :assignment_pmd_settings, :dependent => :destroy
  
  has_one :grade_item, :dependent => :destroy
  
  has_one :auto_grade_setting, :dependent => :destroy
  
  has_one :quiz, :dependent => :destroy
  
  has_many :io_checks, :dependent => :destroy
  
  has_many :extensions, :dependent => :destroy
  
  has_many :team_filters, :dependent => :destroy
  
  has_many :rubrics, :order => "position", :dependent => :destroy

  has_one :item, :dependent => :destroy
  
  
  validates_presence_of :title
  # NEEDS extended validations
  # open < due <= close dates
  # either (1) description or (2) file uploads
  # if a SVN path is given, that is is appropriate 
  
  before_save :transform_markup

  def create_item()
    inst_id = self.user.id rescue inst_id = 0
    
    item = Item.new
    item.user_id = inst_id
    item.course_id = self.course.id
    item.body = "A new assignment '#{self.title}' is now available for #{self.course.short_description}. " +
        "This assignment is due at #{self.close_date.to_formatted_s(:compact_date)}."
    item.enable_comments = true
    item.enable_reshare = false
    item.assignment_id = self.id
    item.created_at = self.open_date
    return item
  end

  def publish(graded_item = false)
    published = false
    Item.transaction do
      # Double check there there is not an item
      item = if graded_item
               Item.find(:first, :conditions => ["graded_assignment_id = ?", self.id], :lock => true)
             else
               Item.find(:first, :conditions => ["assignment_id = ?", self.id], :lock => true)
            end
      if item.nil? && self.visible
        item = if graded_item
                 self.create_graded_item()
               else
                 self.create_item()
               end
        item.save
        item.share_with_course(self.course, item.created_at)
        published = true
      end
    end
    return published
  end

  def create_graded_item()
    inst_id = self.user.id rescue inst_id = 0
    
    item = Item.new
    item.user_id = inst_id
    item.course_id = self.course.id
    item.body = "Grades for '#{self.title}' are now available (#{self.course.short_description}). See how you did!"
    item.enable_comments = true
    item.enable_reshare = false
    item.graded_assignment_id = self.id
    item.created_at = Time.now
    return item  
  end
  
  def clone_to_course( course_id, user_id, time_offset, external_dir )    
    cloneToCourse = Course.find(course_id)
    
    category_map = GradeCategory.ensure_super_set_of( cloneToCourse, self.course )
    defaultCategory = category_map[category_map.keys.first]
    
    dup = Assignment.new
    dup.course_id = course_id
    dup.position = self.position
    dup.title = self.title
    dup.user_id = self.user_id
    dup.open_date = Time.at( self.open_date + time_offset )
    dup.due_date = Time.at( self.due_date + time_offset )
    dup.close_date = Time.at( self.close_date + time_offset )
    dup.description = self.description
    dup.description_html = self.description_html
    dup.file_uploads = self.file_uploads
    dup.enable_upload = self.enable_upload
    dup.enable_journal = self.enable_journal
    dup.programming = self.programming
    dup.use_subversion = self.use_subversion
    dup.subversion_development_path = self.subversion_development_path
    dup.subversion_release_path = self.subversion_release_path
    dup.auto_grade = self.auto_grade
    
    dup.grade_category_id = category_map[self.grade_category.category]
    dup.grade_category_id = defaultCategory if dup.grade_category_id.nil?
    
    dup.released = false
    dup.team_project = self.team_project
    dup.quiz_assignment = self.quiz_assignment
    dup.visible = self.visible
    dup.save
    
    ## Copy any rubrics that exist
    if self.rubrics.size > 0
      self.rubrics.each do |rubric|
        newRubric = rubric.copy_to_course(cloneToCourse)
        newRubric.assignment_id = dup.id
        newRubric.save
      end
    end
    
    ## if grade item
    if self.grade_item
      new_gi = self.grade_item.clone
      new_gi.course_id = course_id
      new_gi.assignment_id = dup.id
      new_gi.date = Time.at( new_gi.date.to_time + time_offset ).to_date
      new_gi.visible = false
      new_gi.grade_category_id = category_map[self.grade_category.category]
      new_gi.grade_category_id = defaultCategory if new_gi.grade_category_id.nil?
      dup.grade_item = new_gi
      dup.save
    end

    # Copy journal fields if needed
    unless self.journal_field.nil?
      new_jf = JournalField.new
      new_jf.copy_from(self.journal_field)
      new_jf.assignment_id = dup.id
      new_jf.save
    end

    ## if it is a quiz
    if self.quiz
      new_quiz = Quiz.new
      new_quiz.assignment = dup
      new_quiz.attempt_maximum = self.quiz.attempt_maximum
      new_quiz.random_questions = self.quiz.random_questions
      new_quiz.number_of_questions = self.quiz.number_of_questions
      new_quiz.linear_score = self.quiz.linear_score
      new_quiz.survey = self.quiz.survey
      new_quiz.available_to_auditors = self.quiz.available_to_auditors
      new_quiz.anonymous = self.quiz.anonymous
      new_quiz.entry_exit = self.quiz.entry_exit
      new_quiz.course_id = course_id
      new_quiz.show_elapsed = self.quiz.show_elapsed
      dup.quiz = new_quiz
      dup.save
      
      # clone questions
      self.quiz.clone_questions( new_quiz )
      new_quiz.save
    end
    
    if self.assignment_documents.size > 0
      # have docs - need to copy them
      external_dir = "#{external_dir}/" unless external_dir[-1] == '/'

      full_path = "#{external_dir}term/#{dup.course.term.id}/course/#{dup.course.id}/assignments"
      FileUtils.mkdir_p full_path
      
      self.assignment_documents.each do |asgn_doc|
        new_doc = AssignmentDocument.new
        new_doc.assignment = dup
        new_doc.position = asgn_doc.position
        new_doc.filename = asgn_doc.filename
        new_doc.content_type = asgn_doc.content_type
        new_doc.created_at = Time.at( asgn_doc.created_at + time_offset )
        new_doc.extension = asgn_doc.extension
        new_doc.size = asgn_doc.size
        new_doc.add_to_all_turnins = asgn_doc.add_to_all_turnins
        new_doc.keep_hidden = asgn_doc.keep_hidden      
        new_doc.save
        
        # actually copy the file
        from_file_name = asgn_doc.resolve_file_name( external_dir )
        to_file_name = new_doc.resolve_file_name( external_dir )
        `cp #{from_file_name} #{to_file_name}`
      end
      
    end
    
    return dup
  end

  ## Builds a map of rubric_id to rubric_entry instance for a specific user.
  def rubric_map_for_user(user_id, create_missing = true)
    rubric_entry_map = Hash.new
    user_rubrics = RubricEntry.find(:all, :conditions => ["assignment_id = ? and user_id=?", self.id, user_id])
    self.rubrics.each do |rubric|
      this_rubric_entry = nil
      user_rubrics.each do |user_rubric|
        this_rubric_entry = user_rubric if user_rubric.rubric_id == rubric.id  
      end  
      # if there isn't a rubric entry for this, we'll create one now
      if this_rubric_entry.nil? && create_missing
        this_rubric_entry = RubricEntry.create_rubric_entry( @assignment, @student, rubric )
        this_rubric_entry.above_credit = false
        this_rubric_entry.full_credit = false
        this_rubric_entry.partial_credit = false
        this_rubric_entry.no_credit = false
        # this save may not work -- but it should, if it fails, it is for a duplicate key issue, race condition
        this_rubric_entry.save rescue true == true
      end      
      
      rubric_entry_map[rubric.id] = this_rubric_entry
    end
    return rubric_entry_map
  end

  def toggle_visibility
    self.visible = !self.visible
  end

  def default_dates
    self.open_date = Time.now
    self.due_date = self.open_date + 1.day
    self.close_date = self.open_date + 1.day
  end
  
  def is_quiz?
    ! self.quiz.nil?
  end
  
  def make_quiz
    self.quiz_assignment = true
    self.programming = false
    self.use_subversion = false
    self.auto_grade = false
  end
  
  def enabled_for_students_team?( user_id )
    team = self.course.team_for_user( user_id )
    team_id = team.id rescue team_id = 0
    enabled_for_team?( team_id )
  end
  
  def enabled_for_team?( team_id )
    return true if self.team_filters.size == 0
    allowed = false
    self.team_filters.each do |team|
      allowed = true if team.project_team_id == team_id
    end
    allowed
  end
  
  def team_filter_set?( team_id )
    filter_set = false
    self.team_filters.each do |team|
      filter_set = true if team.project_team_id == team_id
    end
    filter_set
  end
  
  def ensure_style_defaults
    already_have = Hash.new
    self.assignment_pmd_settings.each do |x|
      already_have[x.style_check_id] = true
    end
    
    pmds = StyleCheck.find(:all, :order => "name asc" )
    # create a new assignment_pmd_setting object for each pmd
    pmds.each do |pmd|
      unless already_have[pmd.id]
        a_pmd_s = AssignmentPmdSetting.new
        a_pmd_s.assignment = @assignment
        a_pmd_s.style_check = pmd
        a_pmd_s.enabled = pmd.bias
        self.assignment_pmd_settings << a_pmd_s
      end
    end
    return self.save
  end
  
  def pmd_hash
    h = Hash.new
    assignment_pmd_settings.each do |apmd|
      h[apmd.style_check.id.to_i] = apmd
    end
    return h
  end
  
  def summary_date
    open_date.to_date.to_formatted_s(:short)
  end
  
  def feed_action
    "Assignment Posted"
  end
  
  def acronym
     'Assignment'
  end
  
  def summary_title
    self.title
  end
  
  def summary_actor
    due_date.to_formatted_s(:friendly_date)
  end
  
  def summary_action
    'due'
  end
  
  def icon
    'icon-calendar'
  end
  
  def upcoming?
    Time.now < open_date
  end
  
  def extension_for_user( user ) 
    ext = nil
    self.extensions.each do |i|
      if i.user_id == user.id 
        ext = i
      end
    end
    return ext
  end
  
  def extension_still_valid( user )
    extension = extension_for_user( user ) 
    if extension.nil?
       return false
    else 
       return ! extension.past?
    end
  end
  
  def current?
    td = Time.now
    open_date <= td && td <= due_date
  end
  
  def development_path_replace( uniqueid, team = nil )
    path = subversion_development_path.gsub(/\$uniqueid\$/, uniqueid )
    unless team.nil?
      path = path.gsub(/\$teamid\$/, team.team_id )
    end
    return path
  end
 
  def release_path_replace( uniqueid, team = nil )
    path = subversion_release_path.gsub(/\$uniqueid\$/, uniqueid )
    unless team.nil?
      path = path.gsub(/\$teamid\$/, team.team_id )
    end
    return path
  end
  
  def past?
    Time.now > due_date
  end
  
  def closed?
    Time.now > close_date
  end
  
  def validate
    errors.add_to_base( 'The assignment available date must be before the assignment close date' ) unless close_date > open_date
    errors.add_to_base( 'The assinment due date must be before the assignment close date and after the available date.') unless close_date >= due_date || due_date <= open_date
   
    if ! self.file_uploads && (self.description.nil?  || self.description.size == 0)
      errors.add('description', 'can not be empty if you are not uploading a file.') unless self.quiz
    end
   
    if self.programming && self.use_subversion
      errors.add('subversion_server', 'can not be empty when using subversion.') if subversion_server.nil? || subversion_server.size == 0
      errors.add('subversion_development_path', 'can not be empty when using subversion.') if subversion_development_path.nil? 
    end
   
  end
  
  def transform_markup
	  self.description_html = HtmlEngine.apply_textile( self.description ) unless self.description.nil?
  end
  
  protected :transform_markup
  
  
end
