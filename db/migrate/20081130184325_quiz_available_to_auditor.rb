class QuizAvailableToAuditor < ActiveRecord::Migration
  def self.up
      add_column( :quizzes, :available_to_auditors, :boolean, :null => false, :default => false )
    end

    def self.down
      remove_column( :quizzes, :available_to_auditors )
  end
end
