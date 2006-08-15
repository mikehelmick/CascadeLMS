require 'FileManager'

class Document < ActiveRecord::Base
  belongs_to :course
  acts_as_list :scope => :course
  
  validates_presence_of :title
  
  before_save :transform_markup
  
  def validate
    errors.add_to_base("No file was given") if self.filename.nil? || self.filename.size == 0
  end
  
  def summary_date
    created_at.to_date.to_formatted_s(:short)
  end
  
  def acronym
     'Document'
  end
  
  def summary_action
    'file info:'
  end
  
  def summary_actor
    self.size_text
  end
  
  def summary_title
    self.title
  end
  
  def icon
    'page'
  end
  
  ##   term/:term_id/course/:course_id/documents/doc_:id.extension
  
  def create_file( file_field, path )
    path = "#{path}/" unless path[-1] == '/'
    
    full_path = "#{path}term/#{self.course.term.id}/course/#{self.course.id}/documents"
    FileUtils.mkdir_p full_path
    
    file_name = "#{full_path}/doc_#{self.id}_#{self.filename}"
    File.open( file_name, "w") { |f| f.write(file_field.read) }
    
    self.save
  end
  
  def delete_file( path )
    path = "#{path}/" unless path[-1] == '/'
    full_path = "#{path}term/#{self.course.term.id}/course/#{self.course.id}/documents"
    file_name = "#{full_path}/doc_#{self.id}_#{self.filename}"
    
    begin
      File.delete( file_name )
    rescue
    end
  end
  
  def set_file_props( file_field ) 
    self.filename = FileManager.base_part_of( file_field.original_filename )
    self.content_type = file_field.content_type.chomp
    self.extension = self.filename.split('.').last.downcase
    self.size = file_field.size
  end
  
  def size_text
    FileManager.size_text( self.size )
  end
  
  def resolve_file_name( path )
    path = "#{path}/" unless path[-1] == '/'
    full_path = "#{path}term/#{self.course.term.id}/course/#{self.course.id}/documents"
    "#{full_path}/doc_#{self.id}_#{self.filename}"
  end
  
  def icon_file
    FileManager.icon(self.extension)
  end
  
  def transform_markup
	  self.comments_html = HtmlEngine.apply_textile( self.comments )
  end
  
end
