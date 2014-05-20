class Admin::CourseAdminController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  # don't set on the AJAX calls
  before_filter :set_tab, :except => [ :change_term, :toggle_open, :search, :mergesearch ]
  
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
    @breadcrumb.text = 'Create New Course'
    load_programs()
  end
  
  def edit
    @course = Course.find(params[:id])
    @terms = Term.find(:all)
    @breadcrumb.text = "Edit #{@course.title}"
    @is_edit = true
  end
  
  def create
    @course = Course.create_course(params[:course], params[:term], params[:crn], true)

    if @course.save
      program_id = params[:program_id].to_i rescue program_id = -1
      if program_id > 0
        @program = Program.find(program_id) rescue @program = nil
        unless @program.nil?
          @course.programs << @program
        end
      end

      flash[:notice] = "New course '#{@course.title}' has been created.  Please edit this course to add an instructor to it."
      redirect_to :action => 'index'
    else
      @terms = Term.find(:all)
      @crn = params[:crn]
      load_programs()
      render :action => 'new'
    end
  end
  
  def update
    @course = Course.find(params[:id])
    @term = Term.find(params[:term])
    
    changing_term = false
    old_term_id = 0
    # if term is changing - we need to move items
    if ( @course.term.id != @term.id )
       old_term_id = @course.term.id 
       @course.term = @term
       changing_term = true
    end
    
    if @course.update_attributes(params[:course])
      if changing_term 
        ## Need to update the enrollment
        course_users = CoursesUser.find(:all, :conditions => ["course_id = ? and term_id = ?", @course.id, old_term_id])
        course_users.each do |cu|
          cu.term_id = @course.term.id
          cu.save
        end
        
        # need to do a move of course information
        # make sure that term dir is created
        `mkdir -p #{@app['external_dir']}/term/#{@term.id}/course`
        # move everything
        `mv #{@app['external_dir']}/term/#{old_term_id}/course/#{@course.id} #{@app['external_dir']}/term/#{@term.id}/course/#{@course.id}`
        
      end
      
      flash[:notice] = "Course #{@course.title} (#{@term.semester}) has been updated."
      redirect_to :action => 'edit', :id => @course
    else
      @terms = Term.find(:all)
      @is_edit = true
      render :action => 'edit'
    end
  end
  
  def merge
    course = Course.find(params[:id])
    other = Course.find(params[:course])
    
    begin
      course.merge(other, @app['external_dir'])
      maybe_run_publisher(false, true)
      flash[:notice] = "Courses have been merged successfully."
      redirect_to :action => 'edit', :id => course, :course => nil
    rescue Exception => doh
      flash[:badnotice] = "There was an error merging the courses"
      redirect_to :action => 'edit', :id => course, :course => nil
    end
  end
  
  def mergesearch
    @course = Course.find(params[:id])
    term = @course.term
    
    st = "%#{params[:searchterms].downcase}%"
    @courses = Course.find(:all, :conditions => ["id != ? and term_id = ? and lower(title) like ?", @course.id, @course.term.id, st ] )
    
    render :layout => false
  end
  
  def search
    @course = Course.find(params[:id])
    
    st = params[:searchterms].downcase
    if st.length >= 4
      sv = "%#{st}%"
      @users = User.find(:all, :conditions => ["LOWER(uniqueid) like ? or LOWER(first_name) like ? or LOWER(last_name) like ? or LOWER(preferred_name) like ?", sv, sv, sv, sv ], :order => "uniqueid asc")
    else
      @invalid = true
    end
  
    render :layout => false
  end
  
  def deluser
    @utype = params[:type]
    @course = Course.find(params[:course])
    @course.courses_users.each do |u|
      if u.user_id.to_i == params[:id].to_i
        #puts "found correct user: #{u.user}"
        if @utype.eql?('student')
          u.course_student = false 
          u.dropped = true
        end
        u.course_instructor = false if @utype.eql?('instructor')
        u.course_assistant = false if @utype.eql?('assistant')
        u.course_guest = false if @utype.eql?('guest')
        if u.any_user?
          u.save
        else
          u.destroy
        end
        @course.save
      end
    end
    
    render :nothing => true
  end
  
  def adduser
    @utype = params[:type]
    @course = Course.find(params[:course])
    added = false
    @course.courses_users.each do |u|
      if u.user_id.to_i == params[:id].to_i
        if @utype.eql?('student')
          u.course_student = true 
          u.dropped = false
        end
        u.course_instructor = true if @utype.eql?('instructor')
        u.course_assistant = true if @utype.eql?('assistant')
        u.course_guest = true if @utype.eql?('guest')
        u.term_id = @course.term_id
        u.save
        @course.save
        added = true
      end
    end
    
    unless added
      c = CoursesUser.new
      user = User.find(params[:id])
      c.course = @course
      c.user = user
      c.course_student = false
      c.course_student = true if @utype.eql?('student')
      c.course_instructor = true if @utype.eql?('instructor')
      c.course_assistant = true if @utype.eql?('assistant')
      c.course_guest = true if @utype.eql?('guest')  
      c.term_id = @course.term_id
      @course.feed.subscribe_user(user, false)
      @course.courses_users << c
      @course.save  
    end
    
    @users = @course.students if @utype.eql?('student')
    @users = @course.assistants if @utype.eql?('assistant')
    @users = @course.guests if @utype.eql?('guest')
    @users = @course.instructors if @utype.eql?('instructor')
    
    render :layout => false, :partial => 'userlist'
  end
  
  def set_tab
    @title = 'Course Administration'
    @tab = 'administration'
    @current_term = Term.find_current
    @breadcrumb = Breadcrumb.for_admin()
    @breadcrumb.admin_course = true
  end

  def load_programs()
    @programs = Program.find(:all, :order => 'title asc')
    @program_id = nil
  end
end
