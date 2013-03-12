require 'MyString'
class AddUserIdForDocsAndAssignments < ActiveRecord::Migration
  def self.up
    add_column(:documents, :user_id, :integer, :null => false, :default => 0)
    add_column(:assignments, :user_id, :integer, :null => false, :default => 0)
    
    # Add in an instructor ID for existing items.
    documents = Document.find(:all, :conditions => ["user_id = 0"])
    documents.each do |doc|
      user_id = doc.course.instructors[0].id rescue user_id = 0
      doc.user_id = user_id
      doc.save
    end

    assignments = Assignment.find(:all, :conditions => ["user_id = 0"])
    assignments.each do |assignment|
      user_id = assignment.course.instructors[0].id rescue user_id = 0
      assignment.user_id = user_id
      assignment.save
    end
  end

  def self.down
    remove_column(:documents, :user_id)
    remove_column(:assignments, :user_id)
  end
end
