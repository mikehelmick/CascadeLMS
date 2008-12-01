class CreateQuizQuestionAnswers < ActiveRecord::Migration
  def self.up
    create_table :quiz_question_answers do |t|
      t.column :quiz_question_id, :integer, :null => false
      t.column :position, :integer
      t.column :answer_text, :text
      t.column :correct, :boolean, :null => false, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :quiz_question_answers
  end
end
