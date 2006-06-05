require 'FileManager'

class AssignmentDocument < ActiveRecord::Base
  belongs_to :assignment
  acts_as_list :scope => :assignment
  
  def create_file( file_field, path )
    path = "#{path}/" unless path[-1] == '/'
    
    full_path = "#{path}term/#{self.assignment.course.term.id}/course/#{self.assignment.course.id}/assignments"
    FileUtils.mkdir_p full_path
    
    file_name = "#{full_path}/assignment_doc_#{self.id}_#{self.filename}"
    File.open( file_name, "w") { |f| f.write(file_field.read) }
    
    self.save
  end
  
  def delete_file( path )
    path = "#{path}/" unless path[-1] == '/'
    full_path = "#{path}term/#{self.assignment.course.term.id}/course/#{self.assignment.course.id}/assignments"
    file_name = "#{full_path}/assignment_doc_#{self.id}_#{self.filename}"
    
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
    full_path = "#{path}term/#{self.assignment.course.term.id}/course/#{self.assignment.course.id}/assignments"
    "#{full_path}/assignment_doc_#{self.id}_#{self.filename}"
  end
  
  def icon_file
    FileManager.icon(self.extension)
  end
  
  
end
