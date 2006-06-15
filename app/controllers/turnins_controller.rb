class TurninsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  
  # list the turnins for this assignment ( shows most recent )
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    # load turnin sets
    @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    @display_turnin = @current_turnin
    
    @now = Time.now
    set_title
  end
  
  def view
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    @display_turnin = UserTurnin.find( params[:id] ) rescue @display_turnin = UserTurnin.new
    return unless user_owns_turnin( @user, @display_turnin )
    return unless turnin_for_assignment( @display_turnin, @assignment )
    
    
    # load turnin sets
    @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    @now = Time.now
    set_title    
  end
  
  def download_set
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
  
    @turnin = UserTurnin.find( params[:id] ) rescue @turnin = UserTurnin.new
    return unless user_owns_turnin( @user, @turnin )
    return unless turnin_for_assignment( @turnin, @assignment )
    
    tf = TempFiles.new
    tf.filename = "#{@app['temp_dir']}/#{@user.uniqueid}_turnin_#{@turnin.id}.tar.gz"
    tf.save_until = Time.now + 60*24*24
    tf.save
    
    directory = @turnin.get_dir( @app['external_dir'] )
    last_part = directory[directory.rindex('/')+1...directory.size]
    first_part = directory[0...directory.rindex('/')]
    
    tar_cmd = "tar -C #{first_part} -czf #{tf.filename} #{last_part}"
    result = `#{tar_cmd} 2>&1`
    
    if result.size > 0 
      flash[:badnotice] = "There was an error creating the download file, please try again later."
      redirect_to :action => 'index', :id => nil
      return
    end
    
    begin  
      send_file tf.filename, :filename => "#{@user.uniqueid}_turnin_#{@turnin.id}.tar.gz"
    rescue
      flash[:badnotice] = "There was an error creating the download file, please try again later."
      redirect_to :action => 'index'
    end   
    
  end
  
  def download_file
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    @utf = UserTurninFile.find( params[:id] )  
    return unless turnin_file_downloadable( @utf )
    @turnin = @utf.user_turnin 
    return unless user_owns_turnin( @user, @turnin )
    return unless turnin_for_assignment( @turnin, @assignment )
    
    # get the file and download it :)
    directory = @turnin.get_dir( @app['external_dir'] )
    
    # resolve file name
    relative_name = @utf.filename
    walker = @utf
    while walker.directory_parent > 0 
      walker = UserTurninFile.find( walker.directory_parent )
      relative_name = "#{walker.filename}/#{relative_name}"
    end
    
    filename = "#{directory}#{relative_name}"
    
    begin  
      send_file filename, :filename => @utf.filename
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your instructor of the problem."
      redirect_to :action => 'index'
    end
  end
  
private
  def turnin_file_downloadable( tif )
    if tif.directory_entry
      flash[:badnotice] = "Individual turn-in directories can not be downloaded"
      redirect_to :action => 'index'
      return false
    end
    true
  end

  def user_owns_turnin( user, turnin )
    unless user.id == turnin.user_id
      flash[:badnotice] = "The requested turn-in set could not be found."
      redirect_to :action => 'index'
    end
    true
  end
  
  def turnin_for_assignment( turnin, assignment )
    unless turnin.assignment_id == assignment.id
      flash[:badnotice] = "The requested turn-in does not belong to this assignment."
      redirect_to :action => 'index'
    end
    true    
  end   

  def assignment_available( assignment, redirect = true )
    unless assignment.open_date <= Time.now
      flash[:badnotice] = "The requisted assignment is not yet available."
      redirect_to :controller => 'assignments', :action => 'index' if redirect
      return false
    end
    true
  end

  def assignment_in_course( assignment, course, redirect = true )
    unless assignment.course_id == course.id 
      flash[:badnotice] = "The requested assignment could not be found."
      redirect_to :controller => 'assignments', :action => 'index' if redirect
      return false
    end
    true
  end
  
  def assignment_open( assignment, redirect = true  ) 
    unless assignment.close_date > Time.now
      flash[:badnotice] = "The requisted assignment is closed, no more files may be submitted."
      redirect_to :action => 'index' if redirect
      return false
    end
    true    
  end

  def set_tab
    @show_course_tabs = true
    @tab = "course_assignments"
    @title = "Course Assignments"
  end

  def set_title
    @title = "Submitted Files for #{@assignment.title} - #{@course.title}" 
  end
  
  
end
