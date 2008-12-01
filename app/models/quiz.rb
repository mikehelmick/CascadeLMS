class Quiz < ActiveRecord::Base
  
  belongs_to :assignment
  
  has_many :quiz_questions, :order => "position", :dependent => :destroy
  
end
