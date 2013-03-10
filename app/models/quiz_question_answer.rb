class QuizQuestionAnswer < ActiveRecord::Base
  
  belongs_to :quiz_question
  acts_as_list :scope => :quiz_question

  before_save :transform_markup
  
  def transform_markup
	  self.answer_text_html = self.answer_text.apply_markup()
	  self.answer_text_html = self.answer_text_html[3..-1] if self.answer_text_html[0..2].eql?("<p>")
	  self.answer_text_html = self.answer_text_html[0...-4] if self.answer_text_html[-4..-1].eql?("</p>")
  end
  
end
