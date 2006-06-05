class CreateAssignmentDocuments < ActiveRecord::Migration
  def self.up
    create_table :assignment_documents do |t|
      t.column :assignment_id, :integer
      t.column :position, :integer
      
      t.column :filename, :string, :null => false
      t.column :content_type, :string, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :extension, :string
      t.column :size, :string
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :assignment_documents
  end
end
