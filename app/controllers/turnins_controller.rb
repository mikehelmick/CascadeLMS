require 'FileManager'
require 'MyString'

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
    
    if @current_turnin
      @directories = Array.new
      @current_turnin.user_turnin_files.each do |utf|
        @directories << utf if utf.directory_entry?
      end
      @directory = ""
    end
  
    count_todays_turnins( @app["turnin_limit"].to_i )
    
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
    
    
    count_todays_turnins
    return unless submissions_remaining()
    
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
  
  def finalize
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    return unless assignment_open( @assignment )
    
    
    count_todays_turnins( @app["turnin_limit"].to_i )
    if @remaining_count <= 0 && @assignment.auto_grade_setting.any_student_grade?
      flash[:badnotice] = "You have reached your finalize limit for today.   The files in this turn-in set will still be submitted to your instructor for evaluation, but you can not finalize the set and run the AutoGrader.   You may archive this set and start a new one if you need to."
      redirect_to :action => 'index'   
      return
    end
    
    # load turnin sets
    @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    @current_turnin.finalized = true
    @current_turnin.sealed = true
    if @current_turnin.save
      flash[:notice] = "Your most recent turn-in set has been finalied and submitted to your instructor."
      
      unless @assignment.auto_grade_setting.nil?
        queue = GradeQueue.new
        queue.user = @user
        queue.assignment = @assignment
        queue.user_turnin = @current_turnin
        if queue.save
          
          begin
            MiddleMan.schedule_worker(
              :class => :auto_grade_worker,
              :args => queue.id,
              :trigger_args => {
                    :start => Time.now + 1.seconds
                  }
            )
          rescue
            flash[:badnotice] = "The AutoGrade server wasn't running - but I've started it up and your grading will be begin shortly."
            ## bounce the server - the stop and then the start (stop has no effect if not running)
            `#{@app['ruby']} #{RAILS_ROOT}/script/backgroundrb stop`
            `#{@app['ruby']} #{RAILS_ROOT}/script/backgroundrb start`
          end
            
          ## need to do a different rediect
          redirect_to :controller => 'wait', :action => 'grade', :id => queue.id
          return
        else
          flash[:badnotice] = "There was an error scheduling your turn-in set for automatic evaluation, pleae inform your instructor or try again."    
        end
        
      end
      
    else
      flash[:badnotice] = "There was an error finalizing your turn-in set, please try again."
    end
    
    
    redirect_to :action => 'index'   
  end
  
  def create_set
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    return unless assignment_open( @assignment )
    
    # load turnin sets
    @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    # create new turning set
    ut = UserTurnin.new
    ut.assignment = @assignment
    ut.user = @user
    ut.sealed = false
    @user.user_turnins << ut
    # create root directory entry
    utf = UserTurninFile.new
    utf.user_turnin = ut
    utf.directory_entry = true
    utf.directory_parent = 0
    utf.filename = '/'
    
    UserTurnin.transaction(ut,utf,@current_transaction) do
      if @current_turnin.nil?
        # this is a new 
        utf.position=1
      else
        utf.position=@current_turnin.position+1
        @current_turnin.sealed = true
      end
    
      # save and create directories
      @user.save
      ut.make_dir( @app['external_dir'] )
      ut.user_turnin_files << utf
      ut.save
      @current_turnin.save unless @current_turnin.nil?
    end
    
    
    redirect_to :action => 'index'
  end
  
  def create_directory
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    return unless assignment_open( @assignment )
    
    ## Validations
    md = params[:newdir].match(/\w+/)
    if ( md.pre_match.size > 0 || md.post_match.size > 0 ) 
      @newdir = params[:newdir]
      flash[:badnotice] = "Thew new directory name may only contain letters and digits, no spaces or special characters."
      redirect_to :action => 'index'
      return
    end
    ## end
    
    @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    # find the nested dir
    nested = nil
    @current_turnin.user_turnin_files.each do |tif|
      nested = tif if tif.id == params[:directory].to_i
    end
    
    # create the new directory
    utf = UserTurninFile.new
    utf.user_turnin = @current_turnin
    utf.directory_entry = true
    utf.directory_parent = nested.id
    utf.filename = params[:newdir]
    
    mover = get_parent( @current_turnin.user_turnin_files, utf )
    fname = utf.filename
    while( mover.directory_parent > 0 )
      fname = prepend_dir( mover.filename, fname )
      mover = get_parent( @current_turnin.user_turnin_files, mover )
    end
    
    UserTurnin.transaction do
      @current_turnin.make_sub_dir( @app['external_dir'], fname )
      @current_turnin.user_turnin_files << utf
      @current_turnin.save
    
      # move the item up
      while( utf.position > nested.position + 1 )
        utf.move_higher
      end
      @current_turnin.save
    end
    
    flash[:notice] = "New directory '#{utf.filename}' created."
    redirect_to :action => 'index'
  end
  
  def change_main
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    return unless assignment_open( @assignment ) 
    
    @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    # all results to the same redirect
    redirect_to :action => 'index'
    
    if @current_turnin.nil?
      flash[:badnotice] = "No turnin set exists."
      return
    end
    
    utf = UserTurninFile.find( params[:id] ) 
    unless utf.main_candidate
      flash[:badnotice] = "The selected file '#{utf.filename}' does not contain a main function."
      return  
    end 
    
    if utf.user_turnin_id == @current_turnin.id
      UserTurnin.transaction do
         
         @current_turnin.user_turnin_files.each do |this_file|
           if this_file.id == utf.id
             this_file.main = true
           else
             this_file.main = false 
           end
           this_file.save
         end
      end
      
      flash[:notice] = "'#{utf.filename}' will be the main file for grading."
      
    else
      flash[:badnotice] = "Selected file is not in the current turnin set."
    end
    
  end
  
  
  def upload_file
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    return unless assignment_open( @assignment )
    
    @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0

    # find the nested dir
    nested = nil
    @current_turnin.user_turnin_files.each do |tif|
      nested = tif if tif.id == params[:directory].to_i
    end
    
    # grab the file
    file_field = params[:file]
    if file_field.nil? || file_field.eql?('')
      flash[:badnotice] = "You must select a file for upload."
      redirect_to :action => 'index'
      return
    end

    # create the new file (but don't save yet)
    @utf = UserTurninFile.new
    @utf.user_turnin = @current_turnin
    @utf.directory_entry = false
    @utf.directory_parent = nested.id
    @utf.filename = FileManager.base_part_of( file_field.original_filename )
    @utf.extension = @utf.filename.split('.').last.downcase

    mover = get_parent( @current_turnin.user_turnin_files, @utf )
    dir_name = ""
    while( mover.directory_parent > 0 )
      dir_name = prepend_dir( mover.filename, dir_name )
      #puts "DIRNAME: #{dir_name}"
      mover = get_parent( @current_turnin.user_turnin_files, mover )
    end
    # dir - is the name of the directory on the file system
    
    dir_name = "#{@current_turnin.get_dir(@app['external_dir'])}/#{dir_name}"
    
    #puts "DIR NAME: #{dir_name}"
    
    UserTurnin.transaction do
      if @utf.create_file( file_field, dir_name )
        @current_turnin.user_turnin_files << @utf
        @current_turnin.save
      
        # move the item up
        while( @utf.position > nested.position + 1 )
          @utf.move_higher
        end
        @current_turnin.save
        
        @current_turnin.calculate_main

        flash[:notice] = "File '#{@utf.filename}' uploaded and stored, you can download the file to verify it was received."
      else
        flash[:badnotice] = "Error saving file, you may not upload two files of the same name to the same directory."
      end
    end
    
    redirect_to :action => 'index'
    
  end
  
  def feedback
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    #return unless comments_released( @assignment )
    
    @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    if @current_turnin
      @directories = Hash.new
      @current_turnin.user_turnin_files.each do |utf|
        @directories[utf.id] = utf if utf.directory_entry?
      end
    end
    
    if @assignment.released
      @grade_item = GradeItem.find( :first, :conditions => ['assignment_id = ?', @assignment.id] )
      if ( @grade_item )
        @grade_entry = GradeEntry.find( :first, :conditions => ['grade_item_id = ? and user_id = ?', @grade_item.id, @user.id] )
        @feedback_html = @grade_entry.comment.to_html rescue @feedback_html = ''
      end
    end
    
    @now = Time.now
    set_title
    
    
    render :layout => 'noright'
  end
  
private

  def submissions_remaining
    unless @remaining_count
      flash[:badnotice] = "You have no remaining submissions for this assignment today."
      redirect_to :action => 'index'
      return false
    end
    return true
  end

  def get_parent( list, current ) 
    return nil if current.directory_parent == 0
    list.each { |x| return x if x.id == current.directory_parent }
  end

  def prepend_dir( newpart, existing )
    "#{newpart}/#{existing}"
  end

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
  
  def count_todays_turnins( max = 3 )
    now = Time.now
    begin_time = Time.local( now.year, now.mon, now.day, 0, 0, 0 )
    end_time = begin_time + 60*60*24 # plus a day
    @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and user_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", @assignment.id, @user.id, true, begin_time, end_time ] )
    @remaining_count = max - @today_count 
    @remaining_count = 0 if @remaining_count < 0
  end
  
  
end
