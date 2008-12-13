class Quiz < ActiveRecord::Base
  
  belongs_to :assignment
  
  has_many :quiz_questions, :order => "position", :dependent => :destroy
  has_many :quiz_attempts, :dependent => :destroy
  
  def user_has_completed_attempt?( user )
    attempt = QuizAttempt.find(:first, :conditions => ["quiz_id=? and user_id=?", self.id, user.id], :order => "created_at desc" )
    return false if attempt.nil?
    return attempt.completed
  end
  
  def all_attempts_for_user( user )
    QuizAttempt.find(:all, :conditions => ["quiz_id=? and user_id=?", self.id, user.id], :order => "created_at desc" )
  end
  
end
