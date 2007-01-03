require 'crn_loader'

class Admin::CrnAdminController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  before_filter :set_tab
  
  def index
    @term = Term.find_current()
    
    @crns = Crn.find(:all, :conditions => ["crn like ?", "#{@term.term}%" ], :order => "name asc" )
    
    @subjects = @app['default_subjects']
  end
  
  def load_crns
    @term = Term.find_current()
    
    @subjects = params[:subjects]
    loader = CrnLoader.new( @term.term, @subjects )
    
    flash[:notice] = loader.load
    
    redirect_to :action => 'index'
  end
  
private
  def set_tab
     @title = 'Course Administration'
     @tab = 'administration'
     @current_term = Term.find_current
   end
  
end
