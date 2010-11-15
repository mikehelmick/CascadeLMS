class AddTermToCoursesUsers < ActiveRecord::Migration
  def self.up
    add_column( :courses_users, :term_id, :int, :null => true, :default => 0 )
    
    add_index(:courses_users, [:user_id, :term_id], :unique => false, :name => 'user_term_idx')
    
    ## Upgrade - wanted to do this in SQL, by puts a dependency on mysql 5...
    CoursesUser.reset_column_information
    all = CoursesUser.find(:all)
    all.each do |cu|
      cu.term_id = cu.course.term_id
      cu.save
    end
    
  end

  def self.down
    remove_index :courses_users, :name => :user_term_idx
    remove_column( :courses_users, :term_id )
  end
end
