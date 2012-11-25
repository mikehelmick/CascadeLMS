class AddItemIndexes < ActiveRecord::Migration
  def self.up
    add_index(:items, :assignment_id, :unique => true)
    add_index(:items, :graded_assignment_id, :unique => true)
    add_index(:items, :post_id, :unique => true)
    add_index(:items, :document_id, :unique => true)
    add_index(:items, :wiki_id,  :unique => true)
    add_index(:items, :forum_post_id,  :unique => true)
  end

  def self.down
    remove_index(:items, :assignment_id)
    remove_index(:items, :graded_assignment_id)
    remove_index(:items, :post_id)
    remove_index(:items, :document_id)
    remove_index(:items, :wiki_id)
    remove_index(:items, :forum_post_id)
  end
end
