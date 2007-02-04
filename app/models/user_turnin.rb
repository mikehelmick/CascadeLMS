class UserTurnin < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user
  
  has_many :user_turnin_files, :order => "position asc", :dependent => :destroy
  
  has_many :io_check_results, :dependent => :destroy
  
  belongs_to :project_team
  
  def team_turnin?
    return !project_team_id.nil?
  end
  
  def get_dir( dir )
    "#{dir}/term/#{assignment.course.term.id}/course/#{assignment.course.id}/turnins/#{user.uniqueid}/assignment_#{assignment.id}/turnin_#{self.id}"  
  end
  
  def any_java_files?
    self.user_turnin_files.each do |utf|
      return true if utf.extension.eql?('java')
    end
    return false
  end
  
  def safe_for_autograde?
    safe = true
    
    self.user_turnin_files.each do |utf|
      if utf.extension.eql?('java')
        if !utf.gradable && !utf.gradable_override
          safe = false
        end
      end
    end
    
    return safe
  end
  
  ## Get the main class for this assignment - including the package path
  def main_class
    ## find file
    main_utf = nil
    self.user_turnin_files.each do |utf|
      main_utf = utf if utf.main
    end
    return '' if main_utf.nil?
    
    ## calculate nesing
    classpath = "#{parent_utf_package( main_utf )}.#{main_utf.filename}"
    classpath = classpath.gsub('..','.')
    
    while classpath[0...1].eql?('.')
      classpath = classpath[1...classpath.length]
    end
    
    if classpath.reverse[0...5].eql?("avaj.")
      classpath = classpath[0...classpath.length-5]
    end
    
    return classpath
  end
  
  def parent_utf_package( utf )
    if utf.directory_parent == 0 
      return ''
    else
      path = ""
      if utf.directory_entry 
        path = utf.filename
      end
      
      parent = nil
      self.user_turnin_files.each do |p_utf|
        parent = p_utf if p_utf.id == utf.directory_parent
      end
      
       return "#{parent_utf_package(parent)}.#{path}"
    end
  end
  
  def calculate_main
    has_candidate = false
    has_main = false
    
    self.user_turnin_files.each do |utf|
      has_candidate ||= utf.main_candidate
      has_main ||= utf.main
    end
    
    if has_candidate && !has_main
      self.user_turnin_files.each do |utf|
        if utf.main_candidate
          utf.main = true
          utf.save
          break
        end
      end
    end
    
  end
  
  def make_sub_dir( dir, chain ) 
    fs_path = "#{get_dir( dir )}/#{chain}"
    FileUtils.mkdir_p( fs_path )
  end
    
  def make_dir( dir )
    fs_path = get_dir(dir)
    FileUtils.mkdir_p( fs_path )
  end
  
  def delete_dir( dir ) 
    fs_path = get_dir( dir )
    FileUtils.remove_dir( fs_path, true )
  end
  
end
