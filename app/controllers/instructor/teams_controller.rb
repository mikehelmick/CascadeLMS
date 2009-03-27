class Instructor::TeamsController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
 
  def index
    return unless load_course( params[:course] )
    return unless teams_enabled( @course )
    return unless ensure_course_instructor( @course, @user )
    
    @teams = @course.project_teams
    @title = "Teams for #{@course.title}"
  end
  
  def new
    return unless load_course( params[:course] )
    return unless teams_enabled( @course )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )    
    
    @team = ProjectTeam.new
    @title = "Create new team for #{@course.title}"
  end
  
  def create
    return unless load_course( params[:course] )
    return unless teams_enabled( @course )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @team = ProjectTeam.new(params[:team])
    @team.course = @course
    if @team.save
      flash[:notice] = 'Team was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end    
  end
  
  def edit
    return unless load_course( params[:course] )
    return unless teams_enabled( @course )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @team = ProjectTeam.find(params[:id])
    
    @title = "Edit team #{@team.name}, course #{@course.title}"
  end
  
  def update
    return unless load_course( params[:course] )
    return unless teams_enabled( @course )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @team = ProjectTeam.find(params[:id])
    if @team.update_attributes(params[:team])
      flash[:notice] = 'Project team was successfully updated.'
      set_highlight( "team_#{@team.id}" )
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end
  
  def team_members
    return unless load_course( params[:course] )
    return unless teams_enabled( @course )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @team = ProjectTeam.find(params[:id]) rescue @team = nil
    return unless team_in_course( @course, @team )
    
    @students = @course.students 
    
    @student_team = Hash.new
    student_teams = TeamMember.find(:all, :conditions => ["course_id = ?", @course.id] )
    student_teams.each do |st|
      @student_team[st.user_id] = st
    end  
    
    @title = "Edit team members for '#{@team.name}'"
  end
  
  def update_team_members
    return unless load_course( params[:course] )
    return unless teams_enabled( @course )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @team = ProjectTeam.find(params[:id])   
    return unless team_in_course( @course, @team )
    
    @students = @course.students
    
    success = false
    TeamMember.transaction do
      ## put the old team members in a map
      old_members = TeamMember.find( :all, :conditions => ["project_team_id = ?", @team.id] )
      om_map = Hash.new
      old_members.each do |om|
        om_map[om.user_id] = om
      end
      
      ## go through all students
      ## create new team members, remove existing from old_members
      @students.each do |student|
        if !params["student_#{student.id}"].nil? && params["student_#{student.id}"].to_i > 0
          
          if ! om_map[student.id].nil?
            om_map.delete( student.id )
          
          else
            tm = TeamMember.new
            tm.project_team = @team
            tm.course = @course
            tm.user = student
            tm.save
          end
          
        end
      end
      
      ## if anything is still in old_members, then it needs to be destroyed
      om_map.each_value do |om|
        om.destroy
      end
      success = true
    end
       
    if success
      flash[:notice] = "The membership of team '#{@team.team_id}' was successfully updated."
    else
      flash[:badnotice] = "There was an error updating team membership."
    end
    
    redirect_to :action => 'index', :id => nil
  end
  
  
  private
  
  def team_in_course( course, team )
    unless !team.nil? && course.id == team.course_id
      flash[:badnotice] = "Requested project team is not in the current course."
      redirect_to :controller => '/instructor/teams', :course => course
      return false
    end
    return true
  end
  
  def teams_enabled( course )
    unless course.course_setting.enable_project_teams
      flash[:badnotice] = "Project teams are not enabled for this course."
      redirect_to :controller => '/instructor/index', :course => course
      return false
    end
    return true
  end
  
  def set_tab
     @show_course_tabs = true
     @tab = "course_instructor"
  end

  def set_title
     @title = "Project Teams - #{@course.title}"
  end
  
end
