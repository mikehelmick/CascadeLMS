class Assignment < ActiveRecord::Base
  belongs_to :course
  acts_as_list :scope => :course
  
  belongs_to :grade_category
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
  
  has_many :rubrics, :order => "position", :dependent => :destroy
  
  
  validates_presence_of :title
  # NEEDS extended validations
  # open < due <= close dates
  # either (1) description or (2) file uploads
  # if a SVN path is given, that is is appropriate 
  
  before_save :transform_markup
  
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
    'calendar.png'
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
