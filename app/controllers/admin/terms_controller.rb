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
    @terms = Term.find( :all, :order => ["term desc"] )
    @title = "All Terms"
  end

  def new
    @term = Term.new
    setup_years
    @term.year = @start_year
    @title = "Create new Term"
  end
  
  def current
    @terms = Term.find( :all )
    @terms.each do |x|
      x.current = false
      x.current = true if x.id == params[:id].to_i
      x.save
    end
    flash[:notice] = 'Current term changed.'
    set_highlight "item_#{params[:id]}"
    redirect_to :action => 'list'
  end
  
  
  def toggle
    @term = Term.find(params[:id])
    @term.open = !@term.open
    @term.save
    
    render(:layout => false)
  end

  def create
    @term = Term.new(params[:term])
    if @term.save
      flash[:notice] = "Term #{@term.semester} was successfully created."
      set_highlight( "item_#{@term.id}" )
      redirect_to :action => 'list'
    else
      render :action => 'new'
      @title = "Create term - error"
    end
  end

  def edit
    @term = Term.find(params[:id])
    setup_years
    @title = "Edit Term - #{@term.semester}"
  end

  def update
    @term = Term.find(params[:id])
    if @term.update_attributes(params[:term])
      flash[:notice] = "Term '#{@term.semester}' was successfully updated."
      set_highlight("item_#{@term.id}")
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
