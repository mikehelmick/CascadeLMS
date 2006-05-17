class Admin::TermsController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin, :set_tab
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @terms = Terms.find( :all, :order => ["term asc"] )
  end

  def new
    @terms = Terms.new
    setup_years
    @term.year = @start_year
  end
  
  def current
    @terms = Terms.find( :all )
    @terms.each do |x|
      x.current = false
      x.current = true if x.id == params[:id].to_i
      x.save
    end
    flash[:notice] = 'Current term changed.'
    flash[:highlight] = "#{params[:id]}"
    redirect_to :action => 'list'
  end
  
  
  def toggle
    @term = Terms.find(params[:id])
    @term.open = !@term.open
    @term.save
    
    render(:layout => false)
  end

  def create
    @term = Terms.new(params[:term])
    if @term.save
      flash[:notice] = 'Terms was successfully created.'
      flash[:highlight] = "#{@term.id}"
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @term = Terms.find(params[:id])
    setup_years
  end

  def update
    @term = Terms.find(params[:id])
    if @term.update_attributes(params[:term])
      flash[:notice] = "Term '#{@term.semester}' was successfully updated."
      flash[:highlight] = "#{@term.id}"
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
  
  def set_tab
     @tab = 'administration'
     @current_term = Term.find(:first, :conditions => ['current = 1'] )
  end
  
  def setup_years
    @start_year = Date.today.year
    @years = Array.new
    (@start_year - 1).upto(@start_year + 5) { |x| @years << x }
  end
   
end
