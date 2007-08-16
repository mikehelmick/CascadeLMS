class ForumLastPost < ActiveRecord::Migration
  def self.up
      add_column( :forum_topics, :last_post, :datetime, :null => true )
    end

    def self.down
      remove_column( :forum_topics, :last_post )
  end
end
