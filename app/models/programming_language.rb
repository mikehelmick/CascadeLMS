class ProgrammingLanguage < ActiveRecord::Base
  
  validates_presence_of :name, :execute_command, :extension
  validates_uniqueness_of :extension
  
  def ProgrammingLanguage.find_by_extension( ext )
    ProgrammingLanguage.find(:first, :conditions => ["extension = ?", ext ] )
  end
  
end
