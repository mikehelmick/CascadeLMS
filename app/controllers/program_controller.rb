class ProgramController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_program_manager, :set_tab
  
  def index
    set_tab
  end
  
  def outcomes
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    set_tab
    
    @program_outcome = ProgramOutcome.new
  end
  
  def save_outcome
    return unless load_program( params[:program] )
    return unless allowed_to_manage_program( @program, @user )    
    
    @program_outcome = ProgramOutcome.new(params[:program_outcome])
    @program_outcome.program = @program
    
     if @program_outcome.save
        set_highlight = "outcome_#{@program_outcome.id}"
        flash[:notice] = 'New outcome has been saved'
        redirect_to :action => 'outcomes', :id => @program
      else
        render :action => 'outcomes', :id => @program
      end
    
  end
  
  def edit
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program_outcome = ProgramOutcome.find params['outcome'] rescue @program_outcome = ProgramOutcome.new
    return unless outcome_for_program( @program, @program_outcome )
  end

  def update_outcome
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program_outcome = ProgramOutcome.find params['outcome'] rescue @program_outcome = ProgramOutcome.new
    return unless outcome_for_program( @program, @program_outcome )  
    
    if @program_outcome.update_attributes(params[:program_outcome])
      flash[:notice] = 'Outcome was successfully updated.'
      set_highlight = "outcome_#{@program_outcome.id}"
      redirect_to :action => 'outcomes', :id => @program
    else
      render :action => 'edit'
    end
    
  end
  
  def destroy
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program_outcome = ProgramOutcome.find params['outcome'] rescue @program_outcome = ProgramOutcome.new
    return unless outcome_for_program( @program, @program_outcome )
    
    @program_outcome.destroy
    flash[:notice] = 'Program Outcome Deleted'
    redirect_to :action => 'outcomes', :id => @program
  end
  
  def sort
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    ProgramOutcome.transaction do
      @program.program_outcomes.each do |outcome|
        outcome.position = params['outcome-order'].index( outcome.id.to_s ) + 1
        outcome.save
      end
    end
        
    render :nothing => true
  end
  
  def move_up
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program_outcome = ProgramOutcome.find params['outcome'] rescue @program_outcome = ProgramOutcome.new
    return unless outcome_for_program( @program, @program_outcome )
    
    (@program.program_outcomes.to_a.find {|s| s.id == @program_outcome.id}).move_higher
    set_highlight "outcome_#{@program_outcome.id}"
  	redirect_to :action => 'outcomes', :id => @program
  end
  
  def move_down
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program_outcome = ProgramOutcome.find params['outcome'] rescue @program_outcome = ProgramOutcome.new
    return unless outcome_for_program( @program, @program_outcome )
    
    (@program.program_outcomes.to_a.find {|s| s.id == @program_outcome.id}).move_lower
    set_highlight "outcome_#{@program_outcome.id}"
  	redirect_to :action => 'outcomes', :id => @program    
  end
  
  def set_tab
    @title = "Program Management - Accreditation Tracking"
    @tab = 'programs'
  end
  
  
end
