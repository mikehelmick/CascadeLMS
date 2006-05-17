class CreateTerms < ActiveRecord::Migration
  def self.up
    create_table :terms do |t|
      t.column :term, :string, :limit => 10, :null => false
      t.column :year, :integer, :null => false
      t.column :semester, :string, :limit => 15, :null => false
      t.column :current, :boolean, :default => false
      t.column :open, :boolean, :default => true
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :terms
  end
end
