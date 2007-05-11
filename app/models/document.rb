require 'FileManager'

class Document < ActiveRecord::Base
  belongs_to :course
  #acts_as_list :scope => :course
  acts_as_list :scope => 'course_id = #{course_id} AND document_parent = #{document_parent}'
  
  validates_presence_of :title
  
  before_save :transform_markup
  
  def validate
    errors.add_to_base("No file was given") if self.filename.nil? || self.filename.size == 0
    
    ## don't let a folder become a podcast if it has subfolders
    if self.podcast_folder
      subs = Document.find(:all, :conditions => ["document_parent = ?", self.id] ) rescue subs = Array.new
      subs.each do |doc|
        if doc.folder
          errors.add_to_base("You can not podcast this directory because it has a subdirectory.")
          return ### THIS MUST BE THE LAST VALIDATION
        end
      end
    end
  end
  
  def feed_action
    'Document Uploaded'
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
  
  def after_destroy
    docs = Document.find( :all, :conditions => ["document_parent = ? and course_id = ?", self.id, self.course_id ] )
    docs.each { |x| x.destroy }
  end
  
  def relative_path( append = "" )
    if self.document_parent == 0
      return "/ #{self.title} / #{append}"
    else
      parent = Document.find( self.document_parent )
      if parent.nil?
        return append
      else
        return parent.relative_path( "#{self.title} / #{append}" )
      end
    end
  end
  
  def parent_document
    return nil if self.document_parent == 0
    return Document.find( self.document_parent )
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
    if self.folder
      'folder'
    else
      FileManager.icon(self.extension)
    end
  end
  
  def transform_markup
	  self.comments_html = HtmlEngine.apply_textile( self.comments )
	  
	  #self.podcast_folder = false if self.folder == false
  end
  
end
