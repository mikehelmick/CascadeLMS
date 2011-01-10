require 'FileManager'
require 'MyString'
require 'auto_grade_helper'

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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    return unless load_team( @course, @assignment, @user )
    load_turnins
    
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    @display_turnin = @current_turnin
    
    unless @current_turnin.nil?
      @directories = Array.new
      @has_files = false
      @current_turnin.user_turnin_files.each do |utf|
        @directories << utf if utf.directory_entry?
        @has_files = @has_files || !utf.directory_entry?
      end
      @directory = ""
      
      
      
    else
      
      redirect_to :action => 'create_set'
      return
      
    end
  
    count_todays_turnins( @app["turnin_limit"].to_i )
    
    # load extneions - if there are any
    @extension = @assignment.extension_for_user( @user )
    
    @now = Time.now
    set_title
  end
  
  def view
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    @display_turnin = UserTurnin.find( params[:id] ) rescue @display_turnin = UserTurnin.new
    return unless load_team( @course, @assignment, @user )
    return unless user_owns_turnin( @user, @display_turnin, @team )
    return unless turnin_for_assignment( @display_turnin, @assignment )
    load_turnins
    
    # load turnin sets
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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
  
    @turnin = UserTurnin.find( params[:id] ) rescue @turnin = UserTurnin.new
    return unless load_team( @course, @assignment, @user )
    return unless user_owns_turnin( @user, @turnin, @team )
    return unless turnin_for_assignment( @turnin, @assignment )
    
    tf = TempFiles.new
    tf.filename = "#{@app['temp_dir']}/#{@user.uniqueid}_turnin_#{@turnin.id}.tar.gz"
    tf.save_until = Time.now + 60*24*24
    tf.save
    
    directory = @turnin.get_dir( @app['external_dir'] )
    directory = @turnin.get_team_dir( @app['external_dir'], @team ) unless @team.nil?
    last_part = directory[directory.rindex('/')+1...directory.size]
    first_part = directory[0...directory.rindex('/')]

    file_list = Array.new
    @turnin.user_turnin_files.each do |utf|
      if !utf.directory_entry && !utf.hidden
        relative_name = utf.filename
        walker = utf
        while walker.directory_parent > 0 
          walker = UserTurninFile.find( walker.directory_parent )
          relative_name = "#{walker.filename}/#{relative_name}"
        end
        
        while( relative_name[0...1].eql?("/") )
            relative_name = relative_name[1..-1] if relative_name.size >= 1 && relative_name[0...1].eql?("/") 
        end
        
        file_list << "#{last_part}/#{relative_name}"
      end
    end
    
    tar_cmd = "tar -C #{first_part} -czf #{tf.filename} #{file_list.join(' ')}"
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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    @utf = UserTurninFile.find( params[:id] )  
    return unless turnin_file_downloadable( @utf )
    if @utf.hidden 
      flash[:badnotice] = "The requested file is not available for download."
      return redirect_to :action => 'index'
    end
    
    
    @turnin = @utf.user_turnin 
    return unless load_team( @course, @assignment, @user )
    return unless user_owns_turnin( @user, @turnin, @team )
    return unless turnin_for_assignment( @turnin, @assignment )
    
    
    count_todays_turnins
    return unless submissions_remaining()
    
    # get the file and download it :)
    directory = @turnin.get_dir( @app['external_dir'] )
    directory = @turnin.get_team_dir( @app['external_dir'], @team ) unless @team.nil?
    
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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    # check extension - we won't check open date if extension is allowd
    @extension = @assignment.extension_for_user( @user )
    if @extension.nil? || (@extension.nil? && !extension.past?)
      return unless assignment_open( @assignment )
    end
    
    return unless load_team( @course, @assignment, @user )
    
    count_todays_turnins( @app["turnin_limit"].to_i )
    if @remaining_count <= 0 && @assignment.auto_grade_setting.any_student_grade?
      flash[:badnotice] = "You have reached your finalize limit for today.   The files in this turn-in set will still be submitted to your instructor for evaluation, but you can not finalize the set and run the AutoGrader.   You may archive this set and start a new one if you need to."
      redirect_to :action => 'index'   
      return
    end
    
    # load turnin sets
    load_turnins
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0
    
    @current_turnin.finalized = true
    @current_turnin.sealed = true
    @current_turnin.force_update = ! @current_turnin.force_update
    if @current_turnin.save
      flash[:notice] = "Your most recent turn-in set has been finalied and submitted to your instructor."
      
      queue = AutoGradeHelper.schedule( @assignment, @user, @current_turnin, @app, flash )
      unless queue.nil?
        ## need to do a different rediect
        redirect_to :controller => 'wait', :action => 'grade', :id => queue.id
        return
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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    return unless load_team( @course, @assignment, @user )
    
    # load turnin sets
    load_turnins
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0

    # check extension - we won't check open date if extension is allowd
    @extension = @assignment.extension_for_user( @user )
    if @extension.nil? || (@extension.nil? && !extension.past?)
      return unless assignment_open( @assignment, true, @current_turnin.nil? )
    end
    
    if !@current_turnin.nil?
      if @current_turnin.user_turnin_files.size == 1
        flash[:badnotice] = "Current turnin set is empty, so it hasn't been archived."
        redirect_to :action => 'index'
        return
      end
    end
    
    
    # create new turning set
    ut = UserTurnin.new
    ut.assignment = @assignment
    ut.user = @user
    ut.sealed = false
    ut.finalized = false
    ## if team - we need to add the team attribute
    ut.project_team = @team unless @team.nil?   
    
    # create root directory entry
    utf = UserTurninFile.new
    utf.user_turnin = ut
    utf.directory_entry = true
    utf.directory_parent = 0
    utf.filename = '/'
    utf.user = @user
    
    UserTurnin.transaction do
      if @current_turnin.nil?
        # this is a new 
        ut.position=1
      else 
        begin
          ut.position=@current_turnin.position+1
        rescue
          ## fix for some bad data that was injected into the database
          @current_turnin.position = 1
          ut.position = 2
        end
        @current_turnin.sealed = true
        
        time = Time.now
        time = Time.local( time.year, time.month, time.mday )
        
        if @current_turnin.updated_at < time && @current_turnin.finalized 
          ## If it was finalized yesterday - we need to un-finalize
          @current_turnin.finalized = false
        end
        
      end
    
      # save and create directories
      # @user.save ## should be no reason to save the user
      ut.save
      ut.make_dir( @app['external_dir'], @team )
      ut.user_turnin_files << utf
      ut.save
      utf.save
      
      ## copy any auto include files
      has_main = false
      @assignment.assignment_documents.each do |asgn_doc|
        if asgn_doc.add_to_all_turnins 
          ## create a user_turnin_file for this
          # create the new file (but don't save yet)
          auto_file = UserTurninFile.new
          auto_file.user_turnin = ut
          auto_file.directory_entry = false
          auto_file.directory_parent = utf.id
          auto_file.filename = asgn_doc.filename
          auto_file.extension = asgn_doc.extension
          auto_file.user = @user
          auto_file.auto_added = true
          auto_file.hidden = asgn_doc.keep_hidden
          # save to get an id
          ut.user_turnin_files << auto_file
          ut.save
          auto_file.save
          
          # copy the bits from the old file to the new file
          from_filename = asgn_doc.resolve_file_name(@app['external_dir'])
          
          # get the file and download it :)
          directory = ut.get_dir( @app['external_dir'] )
          directory = ut.get_team_dir( @app['external_dir'], @team ) unless @team.nil?

          # resolve file name
          relative_name = auto_file.filename
          walker = auto_file
          while walker.directory_parent > 0 
            walker = UserTurninFile.find( walker.directory_parent )
            relative_name = "#{walker.filename}/#{relative_name}"
          end
          to_filename = "#{directory}#{relative_name}"
          
          # actually to the filesystem copy
          `cp #{from_filename} #{to_filename}`
          
          # perform the checks (see if this is a main file)
          auto_file.check_file( "#{directory}/" )
          
          if auto_file.main_candidate && !has_main
            auto_file.main = true
            has_main = true
          end
          
          auto_file.save
          
        end
      end
      
      
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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    # check extension - we won't check open date if extension is allowd
    @extension = @assignment.extension_for_user( @user )
    if @extension.nil? || (@extension.nil? && !extension.past?)
      return unless assignment_open( @assignment )
    end
    
    return unless load_team( @course, @assignment, @user )
    
    ## Validations
    md = params[:newdir].match(/\w+/)
    if ( params[:newdir].nil? || params[:newdir].eql?('') || md.pre_match.size > 0 || md.post_match.size > 0 ) 
      @newdir = params[:newdir]
      flash[:badnotice] = "Thew new directory name can not be empty and may only contain letters and digits, no spaces or special characters."
      redirect_to :action => 'index'
      return
    end
    ## end
    
    load_turnins
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
    utf.user = @user
    
    mover = UserTurninFile.get_parent( @current_turnin.user_turnin_files, utf )
    fname = utf.filename
    while( mover.directory_parent > 0 )
      fname = UserTurninFile.prepend_dir( mover.filename, fname )
      mover = UserTurninFile.get_parent( @current_turnin.user_turnin_files, mover )
    end
    
    UserTurnin.transaction do
      @current_turnin.make_sub_dir( @app['external_dir'], fname, @team )
      @current_turnin.user_turnin_files << utf
      @current_turnin.force_update = ! @current_turnin.force_update
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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    return unless assignment_open( @assignment ) 
    
    return unless load_team( @course, @assignment, @user )
    load_turnins
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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    
    # check extension - we won't check open date if extension is allowd
    @extension = @assignment.extension_for_user( @user )
    if @extension.nil? || (@extension.nil? && !extension.past?)
      return unless assignment_open( @assignment )
    end
    
    return unless load_team( @course, @assignment, @user )
    load_turnins
    @current_turnin = nil
    @current_turnin = @turnins[0] if @turnins.size > 0

    # find the nested dir
    nested = nil
    @current_turnin.user_turnin_files.each do |tif|
      nested = tif if tif.id == params[:directory].to_i
    end
    
    # grab the file
    file_field = params[:file]
    if file_field.nil? || file_field.eql?('') || file_field.class.to_s.eql?('String')
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
    @utf.extension = @utf.filename.split('.').last.downcase rescue @utf.extension = ''
    @utf.user = @user

    # Check extension - we don't accept .class files
    if "class".eql?( @utf.extension ) 
      flash[:badnotice] = "You selected a .class file for submimission.  Compiled Java code is not accepted."
      redirect_to :action => 'index'
      return     
    end

    mover = UserTurninFile.get_parent( @current_turnin.user_turnin_files, @utf )
    dir_name = ""
    while( mover.directory_parent > 0 )
      dir_name = UserTurninFile.prepend_dir( mover.filename, dir_name )
      #puts "DIRNAME: #{dir_name}"
      mover = UserTurninFile.get_parent( @current_turnin.user_turnin_files, mover )
    end
    # dir - is the name of the directory on the file system
    
    if @team.nil?
      dir_name = "#{@current_turnin.get_dir(@app['external_dir'])}/#{dir_name}"
    else
      dir_name = "#{@current_turnin.get_team_dir( @app['external_dir'], @team )}/#{dir_name}"
    end
    
    #puts "DIR NAME: #{dir_name}"
    
    UserTurnin.transaction do
      if @utf.create_file( file_field, dir_name, @app['banned_java'] )
        @current_turnin.user_turnin_files << @utf
        @current_turnin.force_update = ! @current_turnin.force_update
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
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    #return unless comments_released( @assignment )
    
    return unless load_team( @course, @assignment, @user )
    load_turnins
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
    
    if  @assignment.auto_grade_setting && (@assignment.auto_grade_setting.student_io_check || @assignment.released)
      @student_io_check = Hash.new
      @assignment.io_checks.each do |check|
         student_check = IoCheckResult.find(:first, :conditions => ["io_check_id = ? && user_turnin_id = ?", check.id, @current_turnin.id ] )
         unless student_check.nil?
           @student_io_check[check.id] = student_check
         end
      end
    end
    
    # load any existing rubric entries
    if @assignment.rubrics.size > 0
       @rubric_entry_map = Hash.new
       user_rubrics = RubricEntry.find(:all, :conditions => ["assignment_id = ? and user_id=?", @assignment.id, @user.id])
       @assignment.rubrics.each do |rubric|
         user_rubrics.each do |user_rubric|
           @rubric_entry_map[rubric.id] = user_rubric if user_rubric.rubric_id == rubric.id  
         end  
       end
    end
    
    
    @now = Time.now
    set_title
    
    
    respond_to do |format|
      format.html { render :layout => 'noright' }
      format.xml { render :layout => false }
    end
  end
  
  ## Similar to feedback, but line by line difs
  def feedback_line
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    #return unless comments_released( @assignment )
    
    return unless load_team( @course, @assignment, @user )
    load_turnins
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
    
    if  @assignment.auto_grade_setting && (@assignment.auto_grade_setting.student_io_check || @assignment.released)
      @student_io_check = Hash.new
      
      @student_io_check_lines = Hash.new
      
      @assignment.io_checks.each do |check|
         student_check = IoCheckResult.find(:first, :conditions => ["io_check_id = ? && user_turnin_id = ?", check.id, @current_turnin.id ] )
         unless student_check.nil?
           @student_io_check[check.id] = student_check
           
           @student_io_check_lines[check.id] = Hash.new
           @student_io_check_lines[check.id][:EXPECTED] = check.output.split("\n")
           @student_io_check_lines[check.id][:STUDENT] = student_check.output.split("\n")
           @student_io_check_lines[check.id][:DIFF] = student_check.diff_report.split("\n")
           
         end
      end
    end
    
    @now = Time.now
    set_title
    
    render :layout => 'noright'   
  end
  
private

  def load_turnins
    # load turnin sets
    if @assignment.team_project
      @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and project_team_id = ?", @assignment.id, @team.id], :order => "position desc" )
    else
      @turnins = UserTurnin.find( :all, :conditions => [ "assignment_id = ? and user_id = ?", @assignment.id, @user.id ], :order => "position desc" )
    end   
  end

  def submissions_remaining
    unless @remaining_count
      flash[:badnotice] = "You have no remaining submissions for this assignment today."
      redirect_to :action => 'index'
      return false
    end
    return true
  end

  def load_team( course, assignment, user )
    @team = nil
    if assignment.team_project
      @team = course.team_for_user( user.id )
      unless @team.nil?
        return true
      end
      
      flash[:badnotice] = "This is a group project and requires assignment to a team in order to turn in files.  Please contact your instructor to be assigned to a team."
      redirect_to :controller => '/assignments', :action => 'view', :course => course.id, :id => assignment.id
      return false
    end
    return true #no team required
  end

  def turnin_file_downloadable( tif )
    if tif.directory_entry
      flash[:badnotice] = "Individual turn-in directories can not be downloaded"
      redirect_to :action => 'index'
      return false
    end
    true
  end

  def user_owns_turnin( user, turnin, team = nil )
    unless user.id == turnin.user_id || (!team.nil? && turnin.project_team_id == team.id)
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
  
  def assignment_open( assignment, redirect = true, back_to_assignment = false ) 
    unless assignment.close_date > Time.now
      flash[:badnotice] = "The requisted assignment is closed, no more files may be submitted."
      if redirect
        if back_to_assignment 
          redirect_to :controller => '/assignments', :action => 'view', :id => assignment, :course => @course
        else
          redirect_to :action => 'index' 
        end
      end
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
    if @team.nil?
      @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and user_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", @assignment.id, @user.id, true, begin_time, end_time ] )
    else
      @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and project_team_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", @assignment.id, @team.id, true, begin_time, end_time ] )
    end
    @remaining_count = max - @today_count 
    @remaining_count = 0 if @remaining_count < 0
  end
  
  def create_new_turnin_set
    ut = UserTurnin.new
    ut.assignment = @assignment
    ut.user = @user
    ut.sealed = false
    ut.finalized = false
    ## if team - we need to add the team attribute
    ut.project_team = @team unless @team.nil?   
    
    # create root directory entry
    utf = UserTurninFile.new
    utf.user_turnin = ut
    utf.directory_entry = true
    utf.directory_parent = 0
    utf.filename = '/'
    utf.user = @user
    
    return ut, utf
  end
  
  
end
