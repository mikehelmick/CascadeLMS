class CreateCourses < ActiveRecord::Migration
  def self.up
    create_table :courses do |t|
      t.column :term_id, :integer, :null => false
      t.column :title, :string, :null => false
      t.column :short_description, :string, :null => true
      t.column :open, :boolean, :null => false, :default => true
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :courses
  end
end
