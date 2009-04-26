class Public::ApiController < ApplicationController
  
  
  layout 'public'
  
  def program
    @show = true
    begin
      @program = Program.find(params[:id])
      @show = false unless @program.enable_api
    rescue
      @show = false
    end
  
    if ! @show
      flash[:badnotice] = "Invalid program ID specified."
      redirect_to :controller => '/public', :action => nil, :id => nil
      return
    end
       
    @title = "Program outcomes for #{@program.title}"
    respond_to do |format|
      format.html
      format.xml { render :layout => false }
    end
  end
  
  def course_template
    @show = true
    begin
      @course_template = CourseTemplate.find(params[:id])
      @found_one = false
      @course_template.programs.each do |program|
        @found_one = @found_one || program.enable_api
      end
      
      @show = false unless @found_one
    rescue
      @show = false
    end
    
    if ! @show
      flash[:badnotice] = "Invalid course template ID specified."
      redirect_to :controller => '/public', :action => nil, :id => nil
      return
    end
    
    respond_to do |format|
      format.html
      format.xml { render :layout => false }
    end
  end
  
end
