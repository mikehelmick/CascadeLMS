class AddSurveyColumns < ActiveRecord::Migration
  def self.up
      add_column( :quizzes, :anonymous, :boolean, :null => false, :default => false )
      add_column( :quizzes, :entry_exit, :boolean, :null => false, :default => false )
  end

  def self.down
      remove_column( :quizzes, :anonymous )
      remove_column( :quizzes, :entry_exit )
  end
end
