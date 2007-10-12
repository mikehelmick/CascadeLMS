class AddDiffSetting < ActiveRecord::Migration
  def self.up
    Setting.create :name => 'diff_command', :value => '/usr/bin/diff', :description => 'Diff command line program.'
    Setting.create :name => 'wc_command', :value => '/usr/bin/wc', :description => 'WC command line program.'
  end

  def self.down
  end
end
