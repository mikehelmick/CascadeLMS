require 'FileManager'

class UserTurninFile < ActiveRecord::Base
  belongs_to :user_turnin
  acts_as_list :scope => :user_turnin
  validates_uniqueness_of :filename, :scope => [:user_turnin_id, :directory_parent]
  
  has_many :file_comments, :dependent => :destroy
  
  def icon()
    if ( self.directory_entry )
      "folder"
    elsif ( self.extension.nil? )
      "page"
    else
      FileManager.icon( self.extension )
    end
  end
  
  def is_text_file?
    FileManager.is_text_file( self.extension )
  end
  
  def create_file( file_field, path )
    save_res = self.save
    
    if save_res
      path = "#{path}/" unless path[-1] == '/'
  
      FileUtils.mkdir_p path
    
      file_name = "#{path}#{self.filename}"
      puts "FILE NAME: #{file_name}" 
      File.open( file_name, "w") { |f| f.write(file_field.read) }
      puts "FILE WRITTEN"
    end
    
    save_res
  end
  
end
