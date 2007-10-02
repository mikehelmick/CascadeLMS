class Railstat < ActiveRecord::Migration
  def self.up
    create_table :rail_stats do |t|
      t.column :remote_ip, :string
      t.column :country, :string
      t.column :language, :string
      t.column :domain, :string
      t.column :subdomain, :string
      t.column :referer, :string
      t.column :resource, :string
      t.column :user_agent, :string
      t.column :platform, :string
      t.column :browser, :string
      t.column :version, :string
      t.column :created_at, :datetime
      t.column :created_on, :date
      t.column :screen_size, :string
      t.column :colors, :string
      t.column :java, :string
      t.column :java_enabled, :string
      t.column :flash, :string
    end
    add_index :rail_stats, :subdomain
    
    create_table :search_terms do |t|
      t.column :subdomain, :string, :default => ''
      t.column :searchterms, :string, :null => false, :default => ''
      t.column :count, :integer, :null => false, :default => 0
      t.column :domain, :string
    end
    add_index :search_terms, :subdomain
    
    create_table :iptocs do |t|
      t.column :ip_from, :integer, :null => false
      t.column :ip_to, :integer, :null => false
      t.column :country_code2, :string, :null => false
      t.column :country_code3, :string, :null => false
      t.column :country_name, :string, :null => false
    end
    add_index :iptocs, [:ip_from, :ip_to], :unique
  end
  
  def self.down
    drop_table :rail_stats
    drop_table :search_terms
    drop_table :iptocs
  end
end