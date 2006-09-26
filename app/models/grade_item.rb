class GradeItem < ActiveRecord::Base
  
  belongs_to :course
  belongs_to :grade_category
  
  has_many :grade_entries, :dependent => :destroy
  
  belongs_to :assignment
  
  validates_presence_of :name, :display_type
  validates_numericality_of :points
  
  SHOWN_TYPES = [
      [ "Score", "s" ],
      [ "Percentage", "p" ]
    ].freeze
  
end
