class AddQuizQuestionHtmlFormat < ActiveRecord::Migration
  def self.up
      add_column( :quiz_questions, :question_html, :text, :null => true )
      add_column( :quiz_question_answers, :answer_text_html, :text, :null => true )
    end

    def self.down
      remove_column( :quiz_questions, :question_html )
      remove_column( :quiz_question_answers, :answer_text_html )
  end
end
