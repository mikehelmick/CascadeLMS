class Assignment < ActiveRecord::Base
  belongs_to :course
  acts_as_list :scope => :course
  
  belongs_to :grade_category
  has_one :journal_field, :dependent => :destroy
  
  has_many :assignment_documents, :order => "position", :dependent => :destroy
  
  validates_presence_of :title
  # NEEDS extended validations
  # open < due <= close dates
  # either (1) description or (2) file uploads
  # if a SVN path is given, that is is appropriate 
  
  before_save :transform_markup
  
  def validate
    errors.add( 'open_date', 'must be before the assignment\'s close date' ) unless close_date > open_date
    errors.add('due_date', 'must be before the assignment\'s close date ') unless close_date >= due_date
   
    if ! self.file_uploads && (self.description.nil?  || self.description.size == 0)
      errors.add('description', 'can not be empty if you are not uploading a file.')
    end
   
    if self.programming && self.use_subversion
      errors.add('subversion_server', 'can not be empty when using subversion.') if subversion_server.nil? || subversion_server.size == 0
      errors.add('subversion_development_path', 'can not be empty when using subversion.') if subversion_development_path.nil? || subversion_development_path.size == 0
    end
   
  end
  
  def transform_markup
	  self.description_html = HtmlEngine.apply_textile( self.description ) unless self.description.nil?
  end
  
  protected :transform_markup
  
  
end
