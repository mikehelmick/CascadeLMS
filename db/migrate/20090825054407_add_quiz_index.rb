class AddQuizIndex < ActiveRecord::Migration
  def self.up
    add_index(:quiz_question_answers, [:quiz_question_id], :unique => false, :name => :quiz_question_answers_question_id)
    add_index(:quiz_questions, [:quiz_id], :unique => false, :name => :quiz_questions_quiz_id)
  end

  def self.down
    
    remove_index( :quiz_question_answers, :name => :quiz_question_answers_question_id )
    remove_index( :quiz_questions, :name => :quiz_questions_quiz_id )
    
  end
end
