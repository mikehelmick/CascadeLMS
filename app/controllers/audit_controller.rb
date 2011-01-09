class AuditController < ApplicationController
  before_filter :ensure_logged_in, :ensure_program_auditor, :set_audit_term
  before_filter :set_tab, :except => [ :change_term ]

  # Lists all available 
  def index
    @programs = @user.programs_under_audit()
  end

  def program
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)
    load_terms     

    @courses = @program.courses_in_term(@audit_term)
    
    @title = "Auditing for '#{@program.title}'"
  end

  def change_term
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)

    @term = Term.find(params[:term])
    session[:audit_term] = @term
    @audit_term = @term

    @courses = @program.courses_in_term(@audit_term)

    render( :layout => false, :partial => 'courses' )
  end

  def course_outcomes
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course(params[:course])
    return unless course_in_program?( @course, @program )

    @numbers = load_outcome_numbers( @course )
    @title = "Course outcomes (#{@course.title}), Program outcomes (#{@program.title})"

    respond_to do |format|
        format.html { render :layout => 'noright' }
        format.csv  { 
          response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
          response.headers['Content-Disposition'] = "attachment; filename=#{@course.title}_course_outcomes_report.csv"
          render :layout => 'noright' 
        }
    end
  end

  def surveys
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course(params[:course])
    return unless course_in_program?( @course, @program )
    @title = "Entry/Exit surveys for #{@course.title}, program: #{@program.title}"

    load_surveys( @course.id )  
  end
  
  def compare_surveys
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course(params[:course])
    return unless course_in_program?( @course, @program )

    @title = "Entry/Exit survey comparison for #{@course.title}, program: #{@program.title}"

    error_url = url_for(:action => 'surveys', :id => @program, :course => @course)
    entry_exit_survey_compare(error_url)    
  end

  def rubric_report
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
    @title = "Rubric report for #{@course.title}, program: #{@program.title}"

    RubricLevel.for_course( @course )
     
    build_course_rubrics_report()
    
    respond_to do |format|
        format.html { render :layout => 'noright' }
        format.csv  { 
          response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
          response.headers['Content-Disposition'] = "attachment; filename=#{@course.short_description}_course_outcomes_rubrics_report.csv"
          render :layout => 'noright' 
        }
    end
  end

private
  def set_tab
    @tab = 'audit'
  end

  def load_terms
    @terms = Term.find(:all)
  end

  def set_audit_term
    if session[:audit_term].nil?
      session[:audit_term] = Term.find_current
    end
    @audit_term = session[:audit_term]
  end

  def course_in_program?( course, program )
    if course.mapped_to_program?( program.id )
      return true
    end
    
    flash[:badnotice] = "Invalid course requested."
    redirect_to :controller => 'audit', :action => 'program', :id => program
    return false
  end
end
