class Program < ActiveRecord::Base
  
  has_many :programs_users
  has_many :users, :through => :programs_users

  has_many :program_outcomes, :order => "position", :dependent => :destroy

  has_and_belongs_to_many :courses
  
  def managers
    managers = Array.new   
    self.programs_users.each do |i|
      managers << i.user if i.program_manager
    end
    return managers
  end
  
  def auditors
    auditors = Array.new    
    self.programs_users.each do |i|
      auditors << i.user if i.program_auditor
    end
    return auditors   
  end
  
  
end
