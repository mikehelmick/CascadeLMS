class ProgramsUser < ActiveRecord::Base
  belongs_to :program
  belongs_to :user

  def any_user?
    self.program_manager || self.program_auditor
  end
  
  def to_s
    user.to_s
  end
  
end
