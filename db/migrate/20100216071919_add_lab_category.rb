class AddLabCategory < ActiveRecord::Migration
  def self.up
    GradeCategory.create :category => 'Lab', :course_id => 0
  end

  def self.down
  end
end
