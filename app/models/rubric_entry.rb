class RubricEntry < ActiveRecord::Base
  
  belongs_to :assignment
  belongs_to :user
  belongs_to :rubric

  def RubricEntry.create_rubric_entry(assignment, student, rubric )
    this_rubric_entry = RubricEntry.new
    this_rubric_entry.assignment = assignment
    this_rubric_entry.user = student
    this_rubric_entry.rubric = rubric
    return this_rubric_entry
  end
  
end
