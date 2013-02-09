class MakeCoursesPublicByDefault < ActiveRecord::Migration
  def self.up
    change_column(:courses, :public, :boolean, :default => true)
  end

  def self.down
  end
end
