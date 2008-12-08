class CreateQuizAttemptAnswers < ActiveRecord::Migration
  def self.up
    create_table :quiz_attempt_answers do |t|
      t.column :quiz_attempt_id, :integer, :null => false
      t.column :quiz_question_id, :integer, :null => false
      # this could be null if it is a text response
      t.column :quiz_question_answer_id, :integer, :null => true
      t.column :text_answer, :text, :null => true

      t.column :correct, :boolean, :null => false, :default => false

      t.timestamps
    end
    
    add_index(:quiz_attempt_answers, [:quiz_attempt_id], :unique => false)
    add_index(:quiz_attempt_answers, [:quiz_question_id], :unique => false)
  end

  def self.down
    drop_table :quiz_attempt_answers
  end
end
