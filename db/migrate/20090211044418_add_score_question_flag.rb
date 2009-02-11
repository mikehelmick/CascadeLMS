class AddScoreQuestionFlag < ActiveRecord::Migration
  def self.up
    add_column( :quizzes, :show_elapsed, :boolean, :null => false, :default => true )
    add_column( :quiz_questions, :score_question, :boolean, :null => false, :default => true )
  end

  def self.down
    remove_column( :quizzes, :show_elapsed )
    remove_column( :quiz_questions, :score_question )
  end
end
