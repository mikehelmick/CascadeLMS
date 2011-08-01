require 'crn_loader'

class Admin::CrnAdminController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  before_filter :set_tab

  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }
  
  def index
    @term = Term.find_current()
    @crns = Crn.find(:all, :conditions => ["crn like ?", "#{@term.term}%" ])
    
    @sortType = sortType(params[:sort])
    if @sortType.eql?('title')
      @crns.sort! { |a, b| a.title <=> b.title}
    elsif @sortType.eql?('crn')
      @crns.sort! { |a, b| a.crn <=> b.crn}
    elsif
      @crns.sort! { |a, b| a.name <=> b.name}
    end

    @subjects = @app['default_subjects']
  end
  
  def load_crns
    if !@isMuohio
      flash[:badnotice] = "Loading of CRNs is only available at muohio.edu, or if you implement a custom loader."
      return redirect_to :action => 'index', :id => nil
    end
    @term = Term.find_current()
    
    @subjects = params[:subjects]
    loader = CrnLoader.new( @term.term, @subjects )
    
    flash[:notice] = loader.load
    
    redirect_to :action => 'index'
  end

  def edit
    begin
      @term = Term.find_current()
      @crn = Crn.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:badnotice] = "Invalid CRN selected."
      redirect_to :action => 'index', :id => nil
    end
  end
  
  def new
    @crn = Crn.new
  end

  def create
    @crn = Crn.new(params[:crn])
    if @crn.save
      flash[:notice] = 'New CRN was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def update
    begin
      @crn = Crn.find(params[:id])
      if @crn.update_attributes(params[:crn])
        flash[:notice] = 'CRN was successfully updated.'
        redirect_to :action => 'index', :id => nil
      else
        render :action => 'edit', :id => params[:id]
      end
    rescue
      flash[:badnotice] = "Invalid CRN selected."
      redirect_to :action => 'index', :id => nil
    end
  end

  def destroy
    begin
      Crn.find(params[:id]).destroy
      redirect_to :action => 'index'
    rescue
      flash[:badnotice] = "Invalid CRN selected."
      redirect_to :action => 'index', :id => nil
    end
  end
  
private
  def sortType(type)
    return 'name' if type.nil? || type.eql?('name')
    return 'crn' if type.eql?('crn')
    return 'title'
  end

  # Take a direction, returns 1 if asc or nil, returns -1 if otherwise.
  def loadDirection(dir)
    return 1 if dir.nil?
    return 1 if dir.eql("asc")
    return -1
  end

  # Returns the oposite direction, for the next sort
  def directionText(dir)
    return "asc" if dir == -1
    return "desc"
  end

  def set_tab
     @title = 'Course Administration'
     @tab = 'administration'
     @current_term = Term.find_current
   end
  
end
