class ModifyQuizColumns < ActiveRecord::Migration
  def self.up
    
    remove_column( :quizzes, :retake_after_close )
    
    remove_column( :assignments, :quiz )
    add_column( :assignments, :quiz_assignment, :boolean, :null => false, :default => false )
    
    add_column( :quizzes, :linear_score, :boolean, :null => false, :default => false )
    add_column( :quizzes, :survey, :boolean, :null => false, :default => false )
    
  end

  def self.down
    
    remove_column( :quizzes, :survey )
    remove_column( :quizzes, :linear_score )
    
    ## this column was never used - here for consistency
    add_column( :quizzes, :retake_after_close, :boolean, :null => false, :default => false )
    
    remove_column( :assignments, :quiz_assignment )
    add_column( :assignments, :quiz, :boolean, :null => false, :default => false )
    
  end

end
