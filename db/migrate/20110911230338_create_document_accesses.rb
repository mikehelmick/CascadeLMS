class CreateDocumentAccesses < ActiveRecord::Migration
  def self.up
    create_table :document_accesses, :id => false do |t|
      t.column :document_id, :integer
      t.column :user_id, :integer
      t.column :course_id, :integer
      t.timestamps
    end
    add_index(:document_accesses, [:document_id])
    add_index(:document_accesses, [:user_id, :course_id])
    # records are never updated - so created_at is the only intersting time
    remove_column( :document_accesses, :updated_at )
  end

  def self.down
    drop_table :document_accesses
  end
end
