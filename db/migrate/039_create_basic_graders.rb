class CreateBasicGraders < ActiveRecord::Migration
  def self.up
    create_table :basic_graders do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :basic_graders
  end
end
