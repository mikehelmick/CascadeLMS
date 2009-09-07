class Public::IndexController < ApplicationController
  
  layout 'public'
  
  before_filter :set_tab
  before_filter :load_user_if_logged_in
  
  def index
    @term = Term.find_current
    redirect_to :action => 'term', :id => @term
  end
  
  def term
    begin
      @terms = Term.find(:all, :conditions => ["open=?",true], :order => 'term DESC')
      @term = Term.find(params[:id])
      
      @courses = Course.find(:all, :conditions => ['term_id=? and public=?',@term.id,true], :order => 'title ASC')    
    rescue
      flash[:badnotice] = "Error loading public courses in the selected term."
      redirect_to :controller => '/'
    end
  end
  
  def cterm
    redirect_to :action => 'term', :id => params[:id]
  end
  
  def set_tab
     @show_course_tabs = false
     @tab = "public"
     @title = "Public Courses"
   end
  
end
