class Admin::IndexController < ApplicationController
  
  def index
    
    set_tab
  end
  
  def set_tab
    @tab = 'administration'
  end
  
end
