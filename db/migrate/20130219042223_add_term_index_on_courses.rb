class AddTermIndexOnCourses < ActiveRecord::Migration
  def self.up
    add_index(:courses, :term_id, :unique => false)
  end

  def self.down
    remove_index(:courses, :term_id)
  end
end
