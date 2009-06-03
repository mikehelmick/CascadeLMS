class PortfolioController < ApplicationController
  
  before_filter :ensure_logged_in
  
  def index
    redirect_to :controller => '/home', :action => nil, :id => nil
  end
  
  def generate
    @title = "Automatic ePortfolio for #{@user.display_name}"
    
    @courses = @user.courses
    @courses.sort! do |x,y| 
      srt = y.title <=> x.title
      srt = y.term.term <=> x.term.term if srt == 0
      srt
    end
    
    @outcome_numbers = Hash.new
    @courses.each { |course| @outcome_numbers[course.id] = load_outcome_numbers(course) }
    
    programs_hash = Hash.new
    @courses.each do |course| 
      course.programs.each do |program|
        programs_hash[program.id] = program if programs_hash[program.id].nil?
      end
    end
    @programs = programs_hash.values.sort { |x,y| x.title <=> y.title }
    @program_titles = Array.new
    @programs.each { |p| @program_titles << p.title }
    @program_titles.sort!    
    
    # load up rubric entries...
    @rubric_map = Hash.new
    rubric_entries = RubricEntry.find(:all, :conditions => ['user_id = ?', @user.id])
    rubric_entries.each { |re| @rubric_map[re.rubric_id] = re } 
    
    ## load up the rubrics values into specific program outcome buckets
    @program_outcome_counts = Hash.new
    @program_totals = Hash.new
    @program_totals_images = Hash.new
    ## initialize counters
    @programs.each do |program|
      @program_totals[program.id] = [0,0,0] if @program_totals[program.id].nil?
      @program_totals_images[program.id] = [0,0,0] if @program_totals_images[program.id].nil?
      program.program_outcomes.each do |po|
        @program_outcome_counts[po.id] = [0,0,0] if @program_outcome_counts[po.id].nil?
      end
    end
    rubric_entries.each do |re|
      re.rubric.course_outcomes.each do |co|
        co.program_outcomes.each do |po|
          idx = -1
          idx = 2 if re.no_credit
          idx = 0 if re.above_credit || re.full_credit
          idx = 1 if re.partial_credit

          if idx >= 0
            @program_totals[po.program.id][idx] = @program_totals[po.program.id][idx].next 
            @program_outcome_counts[po.id][idx] = @program_outcome_counts[po.id][idx].next 
          end
        end
      end
    end
    @programs.each do |program|
      @program_totals_images[program.id] = @program_totals[program.id]
      while( @program_totals_images[program.id][0] > 40 || @program_totals_images[program.id][1] > 40 || @program_totals_images[program.id][2] > 40)
        @program_totals_images[program.id][0] = @program_totals_images[program.id][0] / 2
        @program_totals_images[program.id][1] = @program_totals_images[program.id][1] / 2
        @program_totals_images[program.id][2] = @program_totals_images[program.id][2] / 2
      end
    end
    
    
    set_tab
    render :layout => 'noright'
  end
  
  private
  
  def set_tab
    @tab = 'portfolio'
    @portfolio_area = true
  end
  
end
