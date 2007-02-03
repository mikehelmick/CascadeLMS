class TeamDocument < ActiveRecord::Base
  
  belongs_to :project_team
  belongs_to :user
  
  def validate
    errors.add_to_base("No file was given") if self.filename.nil? || self.filename.size == 0
  end
  
  ##   term/:term_id/course/:course_id/team/:team_id/doc_:id.extension
  
  def create_file( file_field, path )
    path = "#{path}/" unless path[-1] == '/'
    
    full_path = "#{path}term/#{self.project_team.course.term.id}/course/#{self.project_team.course.id}/team/team_#{self.project_team.id}"
    FileUtils.mkdir_p full_path
    
    file_name = "#{full_path}/doc_#{self.id}_#{self.filename}"
    File.open( file_name, "w") { |f| f.write(file_field.read) }
    
    self.save
  end
  
  def delete_file( path )
    path = "#{path}/" unless path[-1] == '/'
    
    full_path = "#{path}term/#{self.project_team.course.term.id}/course/#{self.project_team.course.id}/team/team_#{self.project_team.id}"
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
    full_path = "#{path}term/#{self.project_team.course.term.id}/course/#{self.project_team.course.id}/team/team_#{self.project_team.id}"
    "#{full_path}/doc_#{self.id}_#{self.filename}"
  end
  
  def icon_file
    FileManager.icon(self.extension)
  end
  
end
