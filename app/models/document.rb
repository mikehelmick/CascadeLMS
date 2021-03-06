require 'FileManager'

class Document < ActiveRecord::Base
  belongs_to :course
  #acts_as_list :scope => :course
  acts_as_list :scope => 'course_id = #{course_id} AND document_parent = #{document_parent}'

  belongs_to :user
  has_one :item, :dependent => :destroy

  validates_presence_of :title

  before_save :transform_markup

  def create_item()
    inst_id = self.user.id rescue inst_id = 0

    item = Item.new
    item.user_id = inst_id
    item.course_id = self.course_id
    doc_word = if self.link 
                 'link'
               else
                 'document'
               end
    item.body = "New #{doc_word}, '#{self.title}' published in #{self.course.short_description}. #{self.comments}"
    item.enable_comments = true
    item.enable_reshare = false
    item.document_id = self.id
    item.created_at = self.created_at
    return item
  end

  def publish()
    published = false
    time = Time.new
    Item.transaction do
      item = Item.find(:first, :conditions => ["document_id = ?", self.id], :lock => true)
      if item.nil? && self.published && self.created_at < time
        item = self.create_item()
        item.save
        item.share_with_course(self.course, self.created_at)
        published = true
      end
    end
    return published
  end

  def visible_to_students
    return self.published && self.created_at < Time.now
  end

  def log_access(user)
    da = DocumentAccess.new
    da.document = self
    da.course_id = course_id
    da.user = user
    da.save
  end

  def access_count()
    DocumentAccess.count_for_document(self)
  end
  
  def clone_to_course( course_id, user_id, time_offset = nil )
    dup = Document.new
    dup.course_id = course_id
    dup.position = self.position
    dup.title = self.title
    dup.filename = self.filename
    dup.content_type = self.content_type
    dup.comments = self.comments
    dup.comments_html = self.comments_html
    dup.extension = self.extension
    dup.size = self.size
    dup.published = self.published
    dup.folder = self.folder
    dup.link = self.link
    dup.url = self.url
    dup.user_id = self.user_id
    dup.document_parent = 0
    if time_offset.nil?
      dup.created_at = self.created_at
    else
      dup.created_at = Time.at( self.created_at + time_offset )
    end
    dup.podcast_folder = self.podcast_folder
    return dup
  end
  
  def validate
    if self.link
      errors.add_to_base("No URL was given") if self.url.nil? || self.url.size == 0
    else
      errors.add_to_base("No file or links was given") if (self.filename.nil? || self.filename.size == 0)
      errors.add_to_base("Filenames cannot contain more than one period ('.') character") unless self.filename.index('.') == self.filename.rindex('.')
      unless self.folder
        errors.add_to_base("All files must have an extension") if self.filename.index(".").nil?
      end
    end
        
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
    'icon-file'
  end
  
  def without_extension
    return filename if self.extension.nil?
    idx = self.filename.rindex(self.extension)
    return self.filename[0...idx-1]
  end
  
  def dot_extension
    return ".#{self.extension}"
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
  
  def ensure_directory_exists( path )
    path = "#{path}/" unless path[-1] == '/'
    
    full_path = "#{path}term/#{self.course.term.id}/course/#{self.course.id}/documents"
    FileUtils.mkdir_p full_path
  end
  
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
    if self.link
      self.filename = ''
      self.content_type = 'url'
      return
    end
    self.filename = FileManager.base_part_of( file_field.original_filename )
    self.content_type = file_field.content_type.chomp rescue self.content_type = 'text'
    self.extension = self.filename.split('.').last
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
      'icon-folder-open'
    elsif self.link
      'icon-circle-arrow-right'
    else
      FileManager.icon(self.extension)
    end
  end

  def toggle_published
    self.published = !self.published
  end

  def transform_markup
    unless self.comments.nil?
      self.comments_html = self.comments.apply_markup()
	  end
	  #self.podcast_folder = false if self.folder == false
  end
  
  def get_parent_folders
    parentDocs = Array.new
    
    curDoc = self
    while curDoc.document_parent != 0   
      parent = Document.find(curDoc.document_parent)
      parentDocs << parent
      curDoc = parent
    end
    
    return parentDocs.reverse
  end  
end
