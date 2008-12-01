class AddSurveyGradeCategory < ActiveRecord::Migration
  def self.up
    GradeCategory.create :category => 'Survey', :course_id => 0
  end

  def self.down
  end
end
