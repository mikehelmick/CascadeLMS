class CatalogController < ApplicationController

  before_filter :ensure_logged_in, :set_tab

  def index
    @programs = Program.find(:all, :order => 'title asc')
    @courses = Hash.new
    
    # It only makes sens 
    @programs.each do |program|
      @courses[program.id] = program.courses_in_term(@term)
    end

    @other_courses = Course.courses_in_term_without_a_program(@term)

    @half_size = @programs.size / 2
    @oc_half_size = @other_courses.size / 2
  end

  def course
    @course = Course.find(params[:id])
    load_outcome_numbers(@course)
    @breadcrumb.text = "#{@course.title}"
    @breadcrumb.link = url_for :action => 'course', :id => @course.id
  end

  def program
    @program = Program.find(params[:id])
    @courses = @program.courses_in_term(@term)
    @breadcrumb.text = "#{@program.title}"
    @breadcrumb.link = url_for :action => 'program', :id => @program.id
  end

  def register
    @course = Course.find(params[:id])

    CoursesUser.transaction do
      cu = CoursesUser.find(:first, :conditions => ["user_id = ? and course_id = ?", @user.id, @course.id], :lock => true)
      
      send_notification = false

      if cu.nil?
        # User is not in the course, add the proposal.
        cu = CoursesUser.new
        cu.user_id = @user.id
        cu.course_id = @course.id
        cu.course_student = false
        cu.course_instructor = false
        cu.course_assistant = false
        cu.course_guest = false
        cu.term_id = @course.term_id
        # proposal columns
        cu.propose_student = true if "student".eql?(params[:type])
        cu.propose_guest = true if "guest".eql?(params[:type])
        cu.save
        flash[:notice] = 'Your request to join this course has been saved. The instructor will be notified.'
        send_notification = true
      else
        if cu.course_student
          flash[:notice] = 'You are already registred as a student in this course.'
          # nothing to do.
        else
          if cu.course_guest && "guest".eql?(params[:type])
            flash[:notice] = 'You already have guest access to this course.'
          else
            # Something to do
            if "student".eql?(params[:type])
              # Save student proposal unless already rejected. To avoid spam.
              unless cu.reject_propose_student
                cu.propose_student = true
                send_notificaiton = true
              end
            end
            if "guest".eql?(params[:type])
              unless cu.reject_propose_guest
                cu.propose_guest = true
                send_notification = true
              end
            end
            
            flash[:notice] = 'Your request to join this course has been saved. The instructor will be notified.'
          end
        end
      end
      
      if send_notification
        message = "#{@user.display_name} has requested #{params[:type]} access to your course, #{@course.title} (#{@course.short_description})."
        link = url_for(:controller => '/instructor/course_users', :course => @course, :only_path => false)
        @course.instructors.each do |instructor|
          Notification.create_proposal(instructor, message, link, @course)
        end
      end
    end
    redirect_to :action => 'course', :id => @course
  end

  private
  def set_tab
    @tab = 'catalog'
    @title = 'Course Catalog'
    @breadcrumb = Breadcrumb.new
    @breadcrumb.catalog = true
  end
end
