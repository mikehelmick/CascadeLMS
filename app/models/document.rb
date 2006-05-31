class Document < ActiveRecord::Base
  belongs_to :course
  
  @@icons = { 'pdf' => 'page_white_acrobat',
              'mp3' => 'music', 'wav' => 'music', 'acc' => 'music', 'ogg' => 'music',
              'doc' => 'page_white_word',
              'ppt' => 'page_white_powerpoint', 'pps' => 'page_white_powerpoint',
              'xls' => 'page_white_excel',
              'java' => 'page_white_cup', 'jar' => 'page_white_cup',
              'cc' => 'page_white_cplusplus', 'c++' => 'page_white_cplusplus',
              'cpp' => 'page_white_cplusplus',
              'cs' => 'page_white_csharp',
              'rb' => 'page_white_ruby',
              'c' => 'page_white_c',
              'zip' => 'page_white_compressed', 'gz' => 'page_white_compressed', 'tar' => 'page_white_compressed',
              'jpg' => 'page_white_camera', 'png' => 'page_white_camera',
              'gif' => 'page_white_camera', 'jpeg' => 'page_white_camera' }
  
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
    
    File.delete( file_name )
  end

  def size_text
    if size.to_i < 1024
      "#{size}b"
    elsif size.to_i < 1024000
      "#{format('%0.2f',size.to_f/1024)}Kb"
    else
      "#{format('%0.2f',size.to_f/1024000)}Mb"
    end
  end
  
  def set_file_props( file_field ) 
    self.filename = base_part_of( file_field.original_filename )
    self.content_type = file_field.content_type.chomp
    self.extension = self.filename.split('.').last.downcase
    self.size = file_field.size
  end
  
  def resolve_file_name( path )
    path = "#{path}/" unless path[-1] == '/'
    full_path = "#{path}term/#{self.course.term.id}/course/#{self.course.id}/documents"
    "#{full_path}/doc_#{self.id}_#{self.filename}"
  end
  
  def icon_file
    icn = @@icons[self.extension]
    icn = 'page_white' if icn.nil?
    return icn
  end

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end
  
end
