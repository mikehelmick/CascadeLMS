class Admin::CourseAdminController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  # don't set on the AJAX calls
  before_filter :set_tab, :except => [ :change_term, :toggle_open ]
  
  def index
    @terms = Term.find(:all)
    @courses = Course.find(:all, :conditions => ["term_id = ?", @current_term.id ], :order => "title asc" )
  end
  
  def change_term
    @courses = Course.find(:all, :conditions => ["term_id = ?", params[:id] ], :order => "title asc" )
    render( :layout => false, :partial => 'courses' )
  end
  
  def toggle_open
    @course = Course.find(params[:id])
    @course.toggle_open
    @course.save
    render( :layout => false, :partial => 'courseopen' )
  end
  
  def new
    @terms = Term.find(:all)
    @course = Course.new
    @course.term = @current_term
    @crn = ''
  end
  
  def edit
    @course = Course.find(params[:id])
    @terms = Term.find(:all)
  end
  
  def create
    @course = Course.new(params[:course])
    @term = Term.find(params[:term])
    @course.term = @term
    
    # if a CRN was provided...
    unless params[:crn].nil?
      crn = Crn.new()
      crn.crn = params[:crn]
      crn.name = @course.title
      crn.save
      @course.crns << crn
    end
    
    if @course.save
      flash[:notice] = "New course '#{@course.title}' has been created.  Please edit this course to add an instructor to it."
      redirect_to :action => 'index'
    else
      @terms = Term.find(:all)
      @crn = params[:crn]
      render :action => 'new'
    end
  end
  
  def update
    @course = Course.find(params[:id])
    @term = Term.find(params[:term])
    @course.term = @term
    
    if @course.update_attributes(params[:course])
      flash[:notice] = "Course #{@course.title} (#{@term.semester}) has been updated."
      redirect_to :action => 'edit', :id => @course
    else
      @terms = Term.find(:all)
      render :action => 'edit'
    end
  end
  
  def set_tab
    @tab = 'administration'
    @current_term = Term.find_current
  end
  
end
