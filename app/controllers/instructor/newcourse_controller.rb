class Instructor::NewcourseController < Instructor::InstructorBase

  before_filter :ensure_logged_in, :ensure_instrctur_or_admin

  def index    
    set_title()
    initialize_with_term(@current_term)
    @createTerm = @current_term

    load_programs()
  end

  def change_term
    set_title()
    
    @createTerm = Term.find(params[:id])
    initialize_with_term(@createTerm)
    render :action => 'index'
  end

  def create
    set_title()
    crnsToAdd = Array.new
    ## Possibly add any other CRNs by id.
    params.keys.each do |key|
      if (key.starts_with?('crn_'))
        crnId = key[4..-1].to_i
        crn = Crn.find(crnId)
        if !crn.nil?
          crnsToAdd << crn
        end
      end
    end

    createNoneCrn = crnsToAdd.empty?
    @course = Course.create_course(params[:course], params[:term], params[:crn], createNoneCrn)
    program_id = params[:program_id].to_i rescue program_id = -1
    if program_id > 0
      @program = Program.find(program_id) rescue @program = nil
      unless @program.nil?
        @course.programs << @program
      end
    end    
    ## Add in the empty CRNs
    crnsToAdd.each { |c| @course.crns << c }

    if @course.save
      c = CoursesUser.new
      c.course = @course
      c.user = @user
      c.course_student = false
      c.course_instructor = true
      c.term_id = @course.term_id
      c.save

      @course.feed.subscribe_user(@user)
      
      flash[:notice] = "New course '#{@course.title}' has been created."
      redirect_to :controller => '/instructor/index', :course => @course
    else
      flash[:badnotice] = "Course create failed."
      @terms = Term.find(:all)
      @crn = params[:crn]
      @createTerm = Term.find(params[:term])
      render :action => 'index'
    end
  end

private
  def load_programs()
    @programs = Program.find(:all, :order => 'title asc')
    @program_id = nil
  end

  def initialize_with_term(term)
    @terms = Term.find(:all)
    @course = Course.new
    @course.term = term
    @crn = ''

    # load the CRNs for the current term
    @allCrns = Crn.find(:all, :conditions => ["crn like ?", "#{term.term}%" ])
    size = @allCrns.size / 2 rescue size = 0
    @column1 = Array.new
    0.upto(size) { |i| @column1 << @allCrns[i] }
    @column2 = Array.new
    (size+1).upto(@allCrns.size-1) { |i| @column2 << @allCrns[i] }
    
    puts @column1.inspect
  end

  def set_title
    @title = "Create a new course"
    @current_term = Term.find_current
    @isLdap = is_using_ldap()
    @breadcrumb = Breadcrumb.new
    @breadcrumb.text = 'Create Course'
  end
  
end
