class CreateQuizzes < ActiveRecord::Migration
  def self.up
    add_column( :assignments, :quiz, :boolean, :null => false, :default => false )
    
    # The quiz is a pass through object for the assignment
    create_table :quizzes do |t|
      t.column :assignment_id, :int, :null => false
      
      t.column :attempt_maximum, :int, :null => false, :default => -1
      t.column :retake_after_close, :boolean, :null => false, :default => true
      
      t.column :random_questions, :boolean, :null => false, :default => false
      t.column :number_of_questions, :int, :null => false, :default => -1
    end
    
    add_index(:quizzes, [:assignment_id], :unique => true)
  end

  def self.down
    drop_table :quizzes
    
    remove_column( :assignments, :quiz )
  end
end
