class Admin::ProgramsController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  before_filter :set_tab
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list  
     @programs = Program.find(:all)
  end

  def show
    @program = Program.find(params[:id])
  end

  def new
    @program = Program.new
  end

  def create
    @program = Program.new(params[:program])
    if @program.save
      flash[:notice] = 'Program was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @program = Program.find(params[:id])
  end

  def update
    @program = Program.find(params[:id])
    if @program.update_attributes(params[:program])
      flash[:notice] = 'Program was successfully updated.'
      redirect_to :action => 'list', :id => nil
    else
      render :action => 'edit'
    end
  end

  def managers
    @program = Program.find(params[:id])
    @managers = @program.managers
    @auditors = @program.auditors
  end
  
  def search
    @program = Program.find(params[:id])
    
    st = params[:searchterms].downcase
    if st.length >= 2
      sv = "%#{st}%"
      @users = User.find(:all, :conditions => ["(instructor=? or admin=? or auditor=? or program_coordinator=?) and (LOWER(uniqueid) like ? or LOWER(first_name) like ? or LOWER(last_name) like ? or LOWER(preferred_name) like ?)", true, true, true, true, sv, sv, sv, sv ], :order => "uniqueid asc")
    else
      @invalid = true
    end
  
    render :layout => false
  end
 
  def deluser
    @utype = params[:type]
    @program = Program.find(params[:program])
    @program.programs_users.each do |u|
      if u.user_id.to_i == params[:id].to_i
        #puts "found correct user: #{u.user}"
        u.program_manager = false if @utype.eql?('manager')
        u.program_auditor = false if @utype.eql?('auditor')
        if u.any_user?
          u.save
        else
          u.destroy
        end
        @program.save
      end
    end
    
    render :nothing => true
  end
  
  def adduser
    @utype = params[:type]
    @program = Program.find(params[:program])
    added = false
    @program.programs_users.each do |u|
      if u.user_id.to_i == params[:id].to_i
        u.program_manager = true if @utype.eql?('manager') && (u.user.instructor || u.user.admin || u.user.program_coordinator)
        u.program_auditor = true if @utype.eql?('auditor') && (u.user.instructor || u.user.admin || u.user.program_coordinator || u.user.auditor)
        u.save
        @program.save
        added = true
      end
    end
    
    unless added
      p = ProgramsUser.new
      user = User.find(params[:id])
      p.program = @program
      p.user = user
      p.program_manager = false
      p.program_manager = true if @utype.eql?('manager') && (user.instructor || user.admin || user.program_coordinator)
      p.program_auditor = true if @utype.eql?('auditor') && (user.instructor || user.admin || user.program_coordinator || user.auditor)
      @program.programs_users << p
      @program.save   
    end
    
    @users = @program.managers if @utype.eql?('manager')
    @users = @program.auditors if @utype.eql?('auditor')
    
    render :layout => false, :partial => 'userlist'
  end
  
  def set_tab 
    @title = 'Programs (Accreditation Categories)'
    @tab = 'administration'
  end

  private :set_tab
  
end
