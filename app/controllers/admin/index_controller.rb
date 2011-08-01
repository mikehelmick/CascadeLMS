class Admin::IndexController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  
  def index
    set_tab
  end
  
  def set_tab
    @title = "CSCW Administration"
    @tab = 'administration'
  end
  
end
