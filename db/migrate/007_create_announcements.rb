class CreateAnnouncements < ActiveRecord::Migration
  def self.up
    create_table :announcements do |t|
      t.column :headline, :string
      t.column :text, :text 
      t.column :start, :datetime
      t.column :end, :datetime
      t.column :user_id, :integer
      t.column :text_html, :text
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :announcements
  end
end
