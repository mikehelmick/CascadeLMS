require 'Syntaxi'

class Instructor::TurninsController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  layout 'application'
  
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual' )
    
    @assignment = Assignment.find( @params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # load the students
    @students = @course.students
    
    if @assignment.enable_journal
      # count journals
      @journal_count = Hash.new
      @students.each do |s|
        @journal_count[s.id] = Journal.count( :conditions => ["user_id=? and assignment_id=?", s.id, @assignment.id ] )
      end
    end
    
    if @assignment.use_subversion || @assignment.enable_upload
      # see if turnins
      @turnin_sets = Hash.new
      @students.each do |s|
        @turnin_sets[s.id] = UserTurnin.count( :conditions => ["user_id=? and assignment_id=?", s.id, @assignment.id ] ) > 0
      end
    end
    
    # load grades
    @grade_item = GradeItem.find(:first, :conditions => ["assignment_id = ?", @assignment.id] )
    if @grade_item
      @grades = Hash.new
      entries = GradeEntry.find(:all, :conditions => ["grade_item_id=?", @grade_item.id ] )
      entries.each do |e|
        @grades[e.user_id] = e.points
      end
    end
    
  end
  
  def view_student
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    # get grade
    # load grades
    @grade_item = GradeItem.find(:first, :conditions => ["assignment_id = ?", @assignment.id] )
    if @grade_item
      @grade_entry = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @grade_item.id, @student.id ] )
      unless @grade_entry
        @grade_entry = GradeEntry.new
      end
    end
    
    # get journals
    @journals = Journal.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "start_time ASC" )
   
    # get turn-in sets
    @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "position DESC" )
    @current_turnin = @turnins[0] rescue @current_turnin = nil
    @display_turnin = @current_turnin
    
    if params[:ut]
      @turnins.each { |x| @display_turnin = x if x.id == params[:ut].to_i }
    end
    
    # calculate time
    elapsed = 0;
    @journals.each do |journal|
      elapsed += journal.end_time - journal.start_time - journal.interruption_time*60
    end
    elapsed = (elapsed / 60).truncate #down to minutes
    @minutes = elapsed % 60
    elapsed -= @minutes

    @days = (elapsed / 1440).truncate
    elapsed -= @days * 1440

    @hours = (elapsed / 60).truncate
    
  end
  
  def submit_grade
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual' )
    
    @assignment = Assignment.find( @params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @student = User.find( params[:id] )
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    # get grade
    # load grades
    @grade_item = GradeItem.find(:first, :conditions => ["assignment_id = ?", @assignment.id] )
    if @grade_item
      @grade_entry = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @grade_item.id, @student.id ] )
      if @grade_entry
        @grade_entry.update_attributes( params[:grade_entry] )
      else
        @grade_entry = GradeEntry.new( params[:grade_entry] )
        @grade_entry.course = @course
        @grade_entry.user = @student
        @grade_entry.grade_item = @grade_item
      end
      
      if @grade_entry.points.to_s.eql?('')
        @grade_entry.destroy
        @grade_entry = nil
      end
    else 
      flash[:badnotice] = "Application error - there is not grade item for this assignment.  Set on up in the GradeBook."
    end
    
    if @grade_entry.nil?
      flash[:notice] = "Grade for '#{@student.display_name}' has been deleted for this assignment (Since no point value was entered)."
    elsif @grade_entry.save
      flash[:notice] = "Grade for '#{@student.display_name}' has been updated to '#{@grade_entry.points}' for this assignment."
    else
      flash[:badnotice] = "Error updating student grade - results not saved."
    end
    redirect_to :action => 'view_student', :id => @student
  end
  
  def download_set
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual' )
    
    @assignment = Assignment.find( @params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @turnin = UserTurnin.find( params[:id] ) rescue @turnin = UserTurnin.new
    return unless turnin_for_assignment( @turnin, @assignment )
    
    tf = TempFiles.new
    tf.filename = "#{@app['temp_dir']}/#{@user.uniqueid}_assignment_#{@assignment.id}_turnin_#{@turnin.id}.tar.gz"
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
      send_file tf.filename, :filename => "#{@user.uniqueid}_assignment_#{@assignment.id}_turnin_#{@turnin.id}.tar.gz"
    rescue
      flash[:badnotice] = "There was an error creating the download file, please try again later."
      redirect_to :action => 'view_student', :id => @turnin.user_id
    end   
    
  end
  
  def download_file
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual' )
    
    @assignment = Assignment.find( @params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @utf = UserTurninFile.find( params[:id] )  
    return unless turnin_file_downloadable( @utf )
    @turnin = @utf.user_turnin 
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
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your system administrator if this problem continues."
      redirect_to :action => 'view_student', :course => @course, :assignment => @assignment, :id => @utf.user_id
    end
  end
  
  def view_file
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual' )
    
    @assignment = Assignment.find( @params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @student = User.find( params[:student] )
    return unless student_in_course( @course, @student )
    
    @utf = UserTurninFile.find( params[:id] )  
    return unless turnin_file_downloadable( @utf )
    @turnin = @utf.user_turnin 
    return unless turnin_for_assignment( @turnin, @assignment )
    
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
      ## to be moved
      command = "#{@app['enscript_command']} -C --pretty-print=#{FileManager.enscript_language(@utf.extension)} --language=html --color -p- -B #{filename}"
      formatted =`#{command}`
      
      @lines = Array.new
      pull = false
      formatted.each_line do |line|
        if !line.upcase.index('<PRE>').nil?
          pull = true
        elsif !line.upcase.index('</PRE>').nil?
          pull = false
        elsif pull
          @lines << line.chomp.gsub(/  /, "&nbsp;&nbsp;" ).gsub(/\t/,"&nbsp;&nbsp;&nbsp;&nbsp;")
        end
      end
      
      ## end to be moved
      
    rescue
      flash[:badnotice] = "Error loading selected file.  Please contact your system administrator."
      redirect_to :action => 'view_student', :course => @course, :assignment => @assignment, :student => nil, :id => @student
      return
    end
    
  end
  
  ## BEGIN PRIVATE UTILITY METHODS
  
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Turins - #{@assignment.title}"
  end
  
  def assignment_in_course( course, assignment )
    unless course.id == assignment.course.id
      redirect_to :controller => '/instructor/index', :course => course
      flash[:notice] = "Requested assignment could not be found."
      return false
    end
    true
  end
  
  def turnin_for_assignment( turnin, assignment )
    unless turnin.assignment_id == assignment.id
      flash[:badnotice] = "The requested turn-in does not belong to this assignment."
      redirect_to :action => 'index', :assignment => assignment.id
    end
    true    
  end
  
  def turnin_file_downloadable( tif )
    if tif.directory_entry
      flash[:badnotice] = "Individual turn-in directories can not be downloaded"
      redirect_to :action => 'index', :assignment => tif.assignment_id
      return false
    end
    true
  end
  
  private :set_tab, :set_title, :assignment_in_course, :turnin_for_assignment, :turnin_file_downloadable
  
end
