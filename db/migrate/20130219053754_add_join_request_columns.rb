class AddJoinRequestColumns < ActiveRecord::Migration
  def self.up
    add_column(:courses_users, :propose_student, :boolean, :null => false, :default => false)
    add_column(:courses_users, :reject_propose_student, :boolean, :null => false, :default => false)
    add_column(:courses_users, :propose_guest, :boolean, :null => false, :default => false)
    add_column(:courses_users, :reject_propose_guest, :boolean, :null => false, :default => false)

    add_column(:notifications, :course_id, :integer, :null => true)
    add_column(:notifications, :proposal, :boolean, :null => true)
    add_index(:notifications, [:user_id, :course_id, :proposal], :unique => false, :name => 'notifications_proposal_index')
  end

  def self.down
    remove_column(:courses_users, :propose_student)
    remove_column(:courses_users, :reject_propose_student)
    remove_column(:courses_users, :propose_guest)
    remove_column(:courses_users, :reject_propose_guest)

    remove_index :notifications, :name => :notifications_proposal_index
    remove_column(:notifications, :course_id)
    remove_column(:notifications, :proposal)
  end
end
