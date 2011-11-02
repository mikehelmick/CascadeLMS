class Admin::IndexController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  
  def index
    set_tab
  end

  def run_upgrade
    Bj.submit "./script/runner ./jobs/social_upgrade.rb"
    flash[:notice] = "Upgrade to CascadeLMS 1.5 is running in the background. The upgrade takes a few minutes."
    redirect_to :action => 'index'
  end
  
  def set_tab
    @title = "CSCW Administration"
    @tab = 'administration'
  end
  
end
