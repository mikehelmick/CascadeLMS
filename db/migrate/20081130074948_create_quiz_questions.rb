class CreateQuizQuestions < ActiveRecord::Migration
  def self.up
    create_table :quiz_questions do |t|
      t.column :quiz_id, :integer, :null => false
      t.column :position, :integer
      t.column :question, :text
      
      t.column :text_response, :boolean, :null => false, :default => false
      t.column :multiple_choice, :boolean, :null => false, :default => true
      t.column :checkbox, :boolean, :null => false, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :quiz_questions
  end
end
