require 'FileManager'

class UserTurninFile < ActiveRecord::Base
  belongs_to :user_turnin
  belongs_to :user
  acts_as_list :scope => :user_turnin
  validates_uniqueness_of :filename, :scope => [:user_turnin_id, :directory_parent]
  
  has_many :file_comments, :dependent => :destroy
  has_many :file_styles, :dependent => :destroy
  
  def dir?
    directory_entry
  end
  
  def without_extension
    return filename if self.extension.nil?
    idx = self.filename.rindex(self.extension)
    return self.filename[0...idx-1]
  end
  
  def dot_extension
    return ".#{self.extension}"
  end
  
  def full_filename( directory_map )
    x = filename
    if ( directory_parent > 0 )
      x = "#{directory_map[directory_parent].full_filename( directory_map )}/#{x}"
    end
  end
  
  # accepts an optional code block to transform comments before display
  def file_comments_hash
    comments = Hash.new
    self.file_comments.each do |fc|
      comments[fc.line_number] = fc
    end
    return comments
  end
  
  def file_style_hash( include_suppressed = false )
    style = Hash.new
    self.file_styles.each do |fs|
      if include_suppressed || !fs.suppressed 
        if style[fs.begin_line].nil?
          style[fs.begin_line] = Array.new
        end
        style[fs.begin_line] << fs
      end
    end
    return style
  end
  
  def icon()
    if ( self.directory_entry )
      "folder.png"
    elsif ( self.extension.nil? )
      "page.png"
    else
      FileManager.icon( self.extension )
    end
  end
  
  def is_text_file?
    FileManager.is_text_file( self.extension )
  end
  
  def check_file( path, banned = Array.new )
    file_name = "#{path}#{self.filename}"
    if FileManager.java?( file_name )
      self.main_candidate = FileManager.java_main?( file_name )
      banned_msg = FileManager.java_banned( file_name, banned )
      if banned_msg.nil? || banned_msg.eql?('')
        self.gradable = true
      else
        self.gradable = false
        self.gradable_message = banned_msg
      end
    end
  end
  
  def create_file( file_field, path, banned = Array.new )
    save_res = self.save
    
    
    if save_res
      path = "#{path}/" unless path[-1] == '/'
  
      FileUtils.mkdir_p path
    
      file_name = "#{path}#{self.filename}"
      #puts "FILE NAME: #{file_name}" 
      File.open( file_name, "w") { |f| f.write(file_field.read) }
      #puts "FILE WRITTEN"
      
      check_file( path, banned )
    end
    
    save_res
  end
  
  def UserTurninFile.get_parent( list, current ) 
    return nil if current.directory_parent == 0
    return UserTurninFile.find( current.directory_parent )
  end

  def UserTurninFile.prepend_dir( newpart, existing )
    "#{newpart}/#{existing}"
  end
  
end
