class AddPortfolioSettings < ActiveRecord::Migration
  def self.up
    Setting.create :name => 'enable_portfolios', :value => 'true', :description => "Enable student ePortfolios."
    Setting.create :name => 'enable_public_portfolios', :value => 'true', :description => "Enable student ePortfolios that are available to the public."
  end

  def self.down
  end
end
