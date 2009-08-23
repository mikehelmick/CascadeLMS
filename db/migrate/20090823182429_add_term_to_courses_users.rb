class AddTermToCoursesUsers < ActiveRecord::Migration
  def self.up
    add_column( :courses_users, :term_id, :int, :null => true, :default => 0 )
    
    add_index(:courses_users, [:user_id, :term_id], :unique => false, :name => :user_term_idx)
    
    ## Upgrade
    execute "update courses_users set term_id=(select term_id from courses where id=course_id)"
    
  end

  def self.down
    remove_index :courses_users, :name => :user_term_idx
    remove_column( :courses_users, :term_id )
  end
end
