# Copyright (c) 2006-2013, Mike Helmick - mike.helmick@gmail.com
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
#  - Redistributions of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer.
#  - Redistributions in binary form must reproduce the above copyright notice, 
#    this list of conditions and the following disclaimer in the documentation 
#    and/or other materials provided with the distribution.
#  - Neither the name of the Mike Helmick, Miami University nor the names of its
#    contributors may be used to endorse or promote products derived from this 
#    software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.

require 'action_controller'
require 'BasicAuthentication'
require 'LdapAuthentication'
require 'yaml'
require 'MyString'
require 'MyActiveRecordHelper'
require 'browser'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  ## CSCW Application version
  @@VERSION = '2.0.043 <em>beta</em> (Jefferson) 20130926'
  
  ## Supress password logging
  filter_parameter_logging :password
  
  layout 'application' rescue puts "couldn't load default layout"
  
  before_filter :app_config, :browser_check, :current_term
  after_filter :pull_msg
  
  @@auth_locations = ['REDIRECT_REDIRECT_X_HTTP_AUTHORIZATION',
                      'REDIRECT_X_HTTP_AUTHORIZATION',
                      'X-HTTP_AUTHORIZATION', 'HTTP_AUTHORIZATION',
                      'Authorization','AUTHORIZATION']                      
     
  @@app = nil
  @@external_dir = nil   
  @@last_update = nil
  
     
  ## Collor array for charting/graphig
  @@colors = ['0000ff','00ff7f','ff007f','ffff00',
              'ff00ff','007fff','ff7f00','00ff00',
              'CB439a','439acb','9acb44',
              '63c537','3763c5','c53763',
              '3b1472','723b14','14723b',
              'c44bc0','c0c44a','4ac0c4',
              '50af8c','8c50af','af8c50',
              '6d7d91','916d7d','7d916d']
     
  def colors( amount = @@colors.length )
    colors = Array.new
    amount = @@colors.length if amount > @@colors.length 
  
    0.upto( amount - 1 ) { |i| colors << @@colors[i] }
    return colors
  end

  def init_breadcrumb
    @breadcrumb = Breadcrumb.new
  end     
                    
  def browser_check
    if request.env['HTTP_USER_AGENT'] && request.env['HTTP_USER_AGENT'].include?('MSIE')
      from_idx = request.env['HTTP_USER_AGENT'].index('MSIE')
      to_idx = request.env['HTTP_USER_AGENT'].index(';', from_idx)
      ver = request.env['HTTP_USER_AGENT'][from_idx+5...to_idx].strip.to_f
      
      if ver >= 7.0 || (!cookies[:ie_override].nil? && cookies[:ie_override].eql?( true.to_s ))
        return true
      else
        if controller_name.eql?("browser")
          return true
        else
          redirect_to :controller => '/browser', :action => 'index'
          return false
        end
      end
    end
  end

  # This is meant to be run via the /index/tickle operation,
  # but just in case, it is also checked anytime a user visits
  # the stream.
  def maybe_run_publisher(do_redirects = true, ignore_timestamp = false)
    status = Status.get_status('tickle')
    
    last_update = Time.at(status.value.to_i).to_i
    now = Time.now.to_i
    if (ignore_timestamp || last_update + (2*60) < now)
      Bj.submit "./script/runner ./jobs/publisher.rb", :priority => 100
      
      status.value = now.to_s
      status.save
      
      render :text => "yes", :layout => false if do_redirects
    else
      render :text => "no", :layout => false if do_redirects
    end
  end
  
  def session_valid?(update_time = true)
     creation_time = session[:creation_time] || Time.now
     if !session[:expiry_time].nil? and session[:expiry_time] < Time.now
        # Session has expired. Clear the current session.
        reset_session    
        return false
     end

     # unless update time suppressed
     if (update_time)
       # Assign a new expiry time, whether the session has expired or not.
       session[:expiry_time] = (@app['session_limit'].to_i).seconds.from_now
     end

     return true
  end
  
  def pull_msg
    if session[:user] && session[:user].notice
      flash[:notice] = "#{flash[:notice]} #{session[:user].notice}"
      session[:user].notice = nil
    end
    if session[:user]
      logger.info("sessionid: #{request.session_options[:id]}")
    end
  end

  def load_majors()
    autocompletes = Autocomplete.find(:all, :conditions => ["category = ?", 'major'], :order => 'value ASC')
    @majors = autocompletes.map { |ac| ac.value }
  end
  
  def ApplicationController.external_dir
    ApplicationController.app
    @@external_dir
  end
  
  def ApplicationController.root_dir
    return RAILS_ROOT
  end
  
  def ApplicationController.app( force = false )
    ## situations where we want to forace a settings reload
    ## 
    if @@app.nil? || force == true || @@last_update.nil?  || @@last_update || @@last_update < Time.now - @@app['settings_reload'].to_i
       @@app = Hash.new

       cfigs = Setting.find(:all)
       cfigs.each do |cfig|
         @@app[cfig.name] = cfig.value
         
         ## do some type conversions based on the setting name 
         @@app[cfig.name] = cfig.value.eql?('true') if cfig.name.eql?('ldap_ssl')
         @@app[cfig.name] = cfig.value.to_i if cfig.name.eql?('ldap_port')  
           
       end

       @@app['version'] = @@VERSION
    end
 		return @@app
  end
  
  def current_term()
    @term = Term.find_current
  end
  
  def app_config( force = false )
    ApplicationController.app( force )
    @app = @@app
 	end
 	
 	def ensure_instructor
    unless session[:user].instructor?
      flash[:badnotice] = "You do not have the rights to view the requested page."
      redirect_to :controller => '/home'
      return false
    end
    return true
  end
  
  def ensure_admin
    unless session[:user].admin? || (!@user.nil? && @user.admin?)
      flash[:badnotice] = "You do not have the rights to view the requested page."
      redirect_to :controller => '/home'
      return false
    end
    @isMuohio = (!request.host.index("muohio.edu").nil? || !request.host.index("miamioh.edu").nil?)
    return true
  end
  
  def ensure_program_manager
    unless session[:user].program_manager?
      flash[:badnotice] = "You do not have the rights to view the requested page."
      redirect_to :controller => '/home'
      return false
    end
    return true    
  end

  def ensure_program_auditor
    unless session[:user].auditor?
      flash[:badnotice] = "You do not have the rights to view the requested page."
      redirect_to :controller => '/home'
      return false
    end
    return true
  end
  
  def nil_or_empty( str )
    return str.nil? || str.eql?('')
  end

  def is_domain_restrict()
    return !@app['authtype']
  end

  def ensure_not_ldap
    unless !@app['authtype'].eql?('ldap')
      redirect_to :action => 'index'
      return false
    end
    return true    
  end
  
  def ensure_basic_auth
    unless @app['authtype'].eql?('basic') || @app['allow_fallback_auth'].eql?(true.to_s)
      redirect_to :action => 'index'
      return false
    end
    return true
  end
 	
 	def boolean_to_text( boolean )
 	  if boolean
 	    "Yes"
    else
      "No"
    end
  end
  
  def disabled_text
    if course.course_open
      ''
    else
      'disabled="disabled"'
    end
  end
  
  def course_open( course, redirect_info = {} )
    unless course.course_open?
      flash[:badnotice] = "The requested action can not be performed, since the course is in archive status."
      redirect_to redirect_info
      return false
    end
    return true
  end
 	
 	def load_user_if_logged_in
 	  unless session[:user].nil?
 	    @user = User.find(session[:user].id)
 	    @notificationCount = @user.notification_count
    end
 	end
 	
 	def ensure_logged_in(update_time = true)
 	  redirect_uri = "#{request.protocol()}#{request.host()}#{request.port_string}#{request.request_uri()}"
 	
 	  if session[:user].nil?
 	    flash[:notice] = "Please log in before proceeding."
 	    session[:post_login] = redirect_uri if request.method.to_s.downcase.eql?("get") # && !redirect_uri.index('/redirect/').nil?
 	    redirect_to :controller => '/index'
 	    return false
    end
    
    if !session_valid?(update_time)
      redirect_to :controller => '/index', :action => 'expired'
      # don't want to accidently clobber post data
      session[:post_login] = "#{request.protocol()}#{request.host()}#{request.port_string}/home"
      session[:post_login] = redirect_uri if request.method.to_s.downcase.eql?("get") # && !redirect_uri.index('/redirect/').nil?
      
      return false
    end
    
    # duplicate user - to keep session down
    @user = User.find(session[:user].id)
    @notificationCount = @user.notification_count
    # Load @browser object, some user agent detection stuff.
    browser()
    return true
  end
  
  def ensure_course_instructor_or_assistant( course, user )
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_instructor || cu.course_assistant
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to perform that action."
    redirect_to :controller => '/overview', :course => course.id
    return false    
  end

  def ensure_instrctur_or_admin
    unless session[:user].instructor || session[:user].admin
      redirect_to :controller => '/home', :action => 'nil', :id => nil
      flash[:badnotice] = "Unrecgonized request."
      return false
    end
    return true
  end
  
  def ensure_course_instructor( course, user )
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_instructor
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to perform that action."
    redirect_to :controller => '/overview', :course => course.id
    return false    
  end

  def ensure_course_instructor_or_ta_with_setting( course, user, *setting )
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_instructor
          return true
        else
          setting.each do |s|
            if cu.course_assistant && course.course_setting.attributes[s]
              return true
            end
          end
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to perform that action."
    redirect_to :controller => '/overview', :course => course.id 
    return false    
  end
  
  def course_is_public( course )
    unless course.public
      flash[:badnotice] = "The selected course is not available to the public."
      redirect_to :controller => '/public'
      return false
    end
    return true
  end

  def allowed_to_view_item(user, item)
    unless item.acl_check?(user)
      flash[:notice] = "That post does not exist."
      redirect_to :controller => '/home', :action => nil, :course => nil, :assignment => nil, :id => nil
      return false
    end
    true
  end
  
  def assignment_available_for_students_team( course, assignment, user_id )
    if course.course_setting.enable_project_teams
      unless assignment.enabled_for_students_team?( user_id )
        flash[:notice] = "The selected assignment is not available."
        redirect_to :action => nil, :controller => '/assignments', :course => course, :assignment => nil, :id => nil
        return false    
      end
    end
    true
  end
  
  def allowed_to_manage_program( program, user, redirect = true )
    unless user.manager_in_program?( program.id )
      flash[:badnotice] = "You are not authorized to view the requested program."
      redirect_to :controller => '/program' if redirect
      return false      
    end
    true
  end

  def allowed_to_audit_program(program, user, redirect = true)
    unless user.auditor_in_program?(program.id)
      flash[:badnotice] = "You are not authorized to audit the requested program."
      redirect_to :controller => '/audit', :action => 'index', :id => nil if redirect
      return false
    end
    true
  end
  
  def allowed_to_see_course( course, user, redirect = true)
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_student || cu.course_assistant || cu.course_instructor || cu.course_guest
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to view the requested course." if redirect
    redirect_to :controller => '/home' if redirect
    return false
  end
  
  def student_in_course( course, student )
    if ! student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested, the student is not enrolled in this course."
      redirect_to :action => 'index'
      return false
    end
    true
  end
  
  def assignment_in_course( assignment, course, redirect = true )
    unless assignment.course_id == course.id 
      flash[:badnotice] = "The requested assignment could not be found."
      redirect_to :controller => 'assignments', :action => 'index', :course => @course if redirect
      return false
    end
    true
  end
  
  def assignment_available( assignment, redirect = true )
    unless assignment.open_date <= Time.now && assignment.visible
      flash[:badnotice] = "The requisted assignment is not yet available."
      redirect_to :action => 'index' if redirect
      return false
    end
    true
  end
  
  def assignment_open( assignment, redirect = true  ) 
    unless assignment.close_date > Time.now
      flash[:badnotice] = "The requisted assignment is closed, no more files or information may be submitted."
      redirect_to :action => 'index' if redirect
      return false
    end
    true    
  end
  
  def outcome_for_program( program, outcome, redirect = true )
    unless outcome.program_id == program.id 
      flash[:badnotice] = "The requested outcome could not be found."
      redirect_to :controller => 'program', :action => 'outcomes', :id => @program if redirect
      return false
    end
    true    
  end
  
  def assignment_has_journals( assignment )
    unless assignment.enable_journal
      flash[:badnotice] = "The selected assignment does not have a journal requirement."
      redirect_to :controller => 'assignments', :action => 'view', :id => assignment.id, :course => @course, :assignment => nil
      return false
    end
    true
  end
  
  def load_course( course_id, redirect = true )
    begin
      @course = Course.find( course_id )
      @course.create_feed
    rescue
      flash[:badnotice] = "Requested course could not be found."
      redirect_to :controller => '/home' if redirect
      return false
    end
  end
  
  def load_program( program_id, redirect = true )
    begin
      @program = Program.find( program_id )
    rescue
      flash[:badnotice] = "Requested program could not be found."
      redirect_to :controller => '/program' if redirect
      return false
    end    
  end

  def load_surveys( course_id )
    # Load up the entry/exit surveys
    @surveys = Quiz.find(:all, :conditions => ["course_id=? and entry_exit=?", course_id, true])
    @surveys.sort! do |a,b|
      a.assignment.open_date <=> b.assignment.open_date
    end
  end
 
  def load_assignment( assignment_id, redirect = true )
    begin
      @assignment = Assignment.find( assignment_id )
    rescue
      flash[:badnotice] = "Requested assignment could not be found."
      redirect_to :controller => '/home' if redirect
      return false
    end
  end
  
  def set_highlight( dom_id )
    flash[:highlight] = dom_id
  end

  def is_using_ldap()
    return @app['authtype'].downcase.eql?('ldap')
  end

  def shibboleth_authenticate()
    if (request.env[@app['shib_field_uid']].nil? || request.env[@app['shib_field_uid']].eql?(''))
      flash[:badnotice] = "You must authenticate before continuing."
      return nil
    end
    
    fieldAffiliation = request.env[@app['shib_field_affiliation']]
    fieldFirstName = request.env[@app['shib_field_firstname']]
    fieldLastName = request.env[@app['shib_field_lastname']]
    fieldEMail = request.env[@app['shib_field_mail']]
    fieldOrgId = request.env[@app['shib_field_org_id']]
    fieldPhone = request.env[@app['shib_field_phone']]
    fieldTitle = request.env[@app['shib_field_title']]
    fieldUniqueId = request.env[@app['shib_field_uid']]
    instructorAffiliation = @app['shib_instructor_affiliation']
    fieldPersistentId = request.env[@app['shib_field_persistent_id']]

    @user = User.find(:first, :conditions => ["uniqueid = ?", fieldUniqueId])
    newUser = true

    # Three cases - user already exists, and has been shibboleth authentacted before. Procede to home.
    # User already exists, but hasn't shibboleth authenticated, show welcome screen.
    # user doesn't exist, create user, show welcome screen.

    if @user.nil?
      @user = User.new
      @user.uniqueid = fieldUniqueId
    else
      # user exists
      if @user.shibboleth_auth
        # user exists and has authenticated with shibboleth before
        newUser = false
      end
    end
      
    # Adjust name, etc based on the shibboleth profile
    # Email is only adjusted the first time, and then can be updated again later
    if newUser
      # If obsfucate the password, this effectievly removes the password for users that had once been on basic auth.
      @user.password = fieldPersistentId
      @user.affiliation = fieldAffiliation
      @user.instructor = !fieldAffiliation.index(instructorAffiliation).nil? rescue @user.instructor = nil
      @user.first_name = fieldFirstName
      @user.last_name = fieldLastName
      @user.email = fieldEMail
      @user.org_id = fieldOrgId
      @user.phone_number = fieldPhone
      @user.title = fieldTitle
      
      @user.shibboleth_auth = true
      @user.create_feed
      @user.save
    end
    
    if !@user.affiliation.eql?(fieldAffiliation)
      # Update the affiliation in case a user becomes an instructor
      @user.affiliation = fieldAffiliation
      @user.instructor = !fieldAffiliation.index(instructorAffiliation).nil?
      @user.save
    end
    if !@user.title.eql?(fieldTitle)
      @user.title = fieldTitle
      @user.save
    end
    

    # Load session variables.
    session[:user] = User.find( @user.id )
    session[:ip] = request.remote_ip
    session[:current_term] = Term.find_current
    return newUser
  end
  
  def authenticate( user, redirect = true, force_basic = false )
    if user.nil? || user.uniqueid.nil? || user.uniqueid.eql?('') || user.password.nil? || user.password.eql?('')
      return false
    end
    
    
    auth = BasicAuthentication.new()
    is_ldap = false
    if @app['authtype'].downcase.eql?('ldap') && !force_basic
      auth = LdapAuthentication.new( @app )
      is_ldap = true
    end    
    
    begin
      @user = auth.authenticate( user.uniqueid, user.password, logger )
      
      unless @user.enabled
        flash[:badnotice] = 'Your account has been suspended, please contact your instructor or system administrator.'
        redirect_to :controller => '/'
        return false
      end
      
      flash[:notice] = nil
      flash[:notice] = @user.notice if @user.notice
      session[:user] = User.find( @user.id )
      session[:ip] = request.remote_ip
      session[:current_term] = Term.find_current
      
      if ( redirect && session[:post_login].nil? )
        redirect_to :controller => 'home' 
      elsif redirect # && !session[:post_login].index("/redirect/").nil? 
        redirect_to session[:post_login] if redirect
      elsif redirect
        redirect_to :controller => 'home'
      end
      # Ensures that there is a feed for each user
      @user.create_feed
      return @user
    rescue SecurityError => doh
      logger.info("Security error, uniqueid: #{user.uniqueid}, error => #{doh}")
      if !force_basic && @app['allow_fallback_auth'].eql?(true.to_s)
        if user.ever_ldap_auth
          @login_error = "Invalid username, or password doesn't match"
          user.password = ''
          render :action => 'index', :layout => 'login'
        else
          return authenticate( user, redirect, true )
        end
      else
        if redirect

          ## should we log this error
          #unless doh.message.index('No such object') || doh.message.index('Invalid credentials')
          #  log_error(doh)
          #end

          @login_error = doh.message
          @user.password = '' 
          render :action => 'index', :layout => 'login' 
        end
        return false
      end
    end
  end
  
  def rss_authorize(realm='Courseware RSS Authentication', errormessage='You must log in to view this page.') 
    # if they are already in an HTTP session (using browser based reader)
    unless session[:user].nil?
      @user = User.find(session[:user].id)
      return @user
    end  
    
    #username, passwd = get_auth_data 
    credArray = 
        authenticate_with_http_basic do |u,p| 
           [u, p]
        end
    
    # check if authorized 
    # try to get user 
    user = User.new()
    user.uniqueid = ''
    user.password = ''
    unless credArray.nil?
      user.uniqueid = credArray[0] 
      user.password = credArray[1] if credArray.size > 1
    end
    
    session[:post_login] = nil
    userObject = authenticate( user, false ) 

    if userObject
      return userObject         
    else  
      # the user does not exist or the password was wrong 
      request_http_basic_authentication(realm)
      return nil
    end 
  end 
  
  def count_todays_turnins( assignment, user, max = 3 )
    now = Time.now
    begin_time = Time.local( now.year, now.mon, now.day, 0, 0, 0 )
    end_time = begin_time + 60*60*24 # plus a day
    @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and user_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", assignment.id, user.id, true, begin_time, end_time ] )
    @remaining_count = max - @today_count 
    @remaining_count = 0 if @remaining_count < 0
  end

  def log_error(exception) 
    super(exception)

    begin
      ErrorMailer.deliver_snapshot(
        @app['error_email'],
        exception, 
        clean_backtrace(exception), 
        session, 
        params, 
        request.env)
    rescue => e
      logger.error(e)
    end
  end
  
  def load_outcome_numbers( course )
    parent_stack = [-1]
    count_stack = [0]
    last_stack_size = 1

    numbers = Hash.new

    course.ordered_outcomes.each do |outcome|
      if outcome.parent == parent_stack[-1] ## Same level 
        count_stack.push( count_stack.pop + 1 ) 
      elsif parent_stack.index( outcome.parent ).nil?  ## New level 
        parent_stack.push outcome.parent 
        count_stack.push 1 
      else ## need to pop back to correct level 
        while (parent_stack[-1] != outcome.parent) 
          parent_stack.pop
          count_stack.pop
        end 
        count_stack.push( count_stack.pop + 1 )
      end 

      numbers[outcome.id] = count_stack.join('.')
    end

    return numbers
  end
  
  def build_course_rubrics_report()
    # for each outcome - array of all rubrics
    @outcome_to_rubrics = Hash.new
    # each entry in this hash has a key of rubric ID, array of 3 values
    @rubrics_sums = Hash.new
    @rubrics_avgs = Hash.new
    
    @outcome_sums = Hash.new
    @outcome_avgs = Hash.new
    # precalculate outcome numbers
    @outcome_position = Hash.new
    
    parent_stack = [-1]
    count_stack = [0]

    @course.ordered_outcomes.each do |outcome|
      if outcome.parent == parent_stack[-1] ## Same level 
        count_stack.push( count_stack.pop + 1 ) 
      elsif parent_stack.index( outcome.parent ).nil?  ## New level 
        parent_stack.push outcome.parent 
        count_stack.push 1 
      else ## need to pop back to correct level 
        while (parent_stack[-1] != outcome.parent) 
          parent_stack.pop
          count_stack.pop
        end 
        count_stack.push( count_stack.pop + 1 )
      end 
      @outcome_position[outcome.id] = "#{count_stack.join('.')})"
     
      @outcome_sums[outcome.id] = [0,0,0] if @outcome_sums[outcome.id].nil?
     
      rubrics = outcome.rubrics.delete_if { |x| x.assignment.nil? }
     
      # for each rubric
      rubrics = rubrics.sort do |a,b| 
                  result = a.assignment.position <=> b.assignment.position
                  result = a.position <=> b.position if result == 0
                  result
                end
      @outcome_to_rubrics[outcome.id] = Array.new if @outcome_to_rubrics[outcome.id].nil?                
      rubrics.each do |rubric|
        @outcome_to_rubrics[outcome.id] << rubric
        
        @rubrics_sums[rubric.id] = [0,0,0]
        @rubrics_avgs[rubric.id] = [0,0,0]
        
        entries = RubricEntry.find(:all, :conditions => ['rubric_id = ?', rubric.id])
        entries.each do |re|
          @rubrics_sums[rubric.id][0] = @rubrics_sums[rubric.id][0]+1 if re.above_credit || re.full_credit
          @rubrics_sums[rubric.id][1] = @rubrics_sums[rubric.id][1]+1 if re.partial_credit
          @rubrics_sums[rubric.id][2] = @rubrics_sums[rubric.id][2]+1 if re.no_credit
        end
        
        0.upto(2) { |i| @outcome_sums[outcome.id][i] = @outcome_sums[outcome.id][i] + @rubrics_sums[rubric.id][i] }
        
        # local average
        sum = @rubrics_sums[rubric.id][0] + @rubrics_sums[rubric.id][1] + @rubrics_sums[rubric.id][2]
        if sum > 0
          0.upto(2) { |i| @rubrics_avgs[rubric.id][i] = @rubrics_sums[rubric.id][i] / sum.to_f * 100 }
        end
      end 
      
      # need to calculate average for the outcome
      sum = @outcome_sums[outcome.id][0] + @outcome_sums[outcome.id][1] + @outcome_sums[outcome.id][2]
      @outcome_avgs[outcome.id] = [0,0,0]
      0.upto(2) { |i| @outcome_avgs[outcome.id][i] = @outcome_sums[outcome.id][i] / sum.to_f * 100 }
      
    end
    
  end
  
  def aggregate_survey_responses( quiz )
    # we can make some assumptions since 
    @answer_count_map = Hash.new
    @question_answer_total = Hash.new
    @text_responses = Hash.new
    
    quiz.quiz_questions.each do |question|
       
      if question.text_response
        @text_responses[question.id] = Array.new
        responses = QuizAttemptAnswer.find(:all,:conditions => ["quiz_question_id = ?", question.id])
        responses.each do |response|
          @text_responses[question.id] << response.text_answer
        end
      
      else
        total_responses = 0
        question.quiz_question_answers.each do |answer|
          responses  = QuizAttemptAnswer.count(:conditions => ["quiz_question_answer_id = ?", answer.id])
          @answer_count_map[answer.id] = responses
          total_responses = total_responses + responses
        end
        @question_answer_total[question.id] = total_responses
        
      end
    end
    
    return @answer_count_map, @question_answer_total, @text_responses
  end
  
  def entry_exit_survey_compare(error_url)
    load_surveys( @course.id )
    
    @selected_surveys = Array.new
    @surveys.each do |survey|
      @selected_surveys << survey unless params["survey_#{survey.id}"].nil?
    end
    @selected_surveys.sort do |a,b|
      a.assignment.close_date <=> b.assignment.close_date
    end
    
    @error_msg = nil
    if @selected_surveys.size == 0
      @error_msg = "You must select either 1 or 2 surveys for the report."
    elsif @selected_surveys.size > 2
      @error_msg = "You can only select a maximum of 2 surveys for the report."
    end
    
    if !@error_msg.nil?
      flash[:badnotice] = @error_msg
      redirect_to error_url
      
    else
      ## Good version - do report
      @all_answer_count_maps = Hash.new
      @all_question_answer_totals = Hash.new
      @all_text_responses = Hash.new

      @surveys.each do |survey|
         @all_answer_count_maps[survey.id], @all_question_answer_totals[survey.id], @all_text_responses[survey.id] =
              aggregate_survey_responses( survey )
      end
      
      @entry = @surveys[0]
      @exit = @surveys[1] rescue @exit = nil

      quest_arrays = Array.new
      @surveys.each { |sur| quest_arrays << sur.quiz_questions }
      same_length = true
      quest_arrays.each do |arr| 
        same_length = same_length && quest_arrays[0].length==arr.length 
      end
      
      ## Check the question content
      
      @outcomes = @course.ordered_outcomes
      @outcome_numbers = load_outcome_numbers( @course )
      
      ## try to mapquestions to outcome numbers
      @quest_outcome_number = Hash.new
      @surveys.each do |survey|
        survey.quiz_questions.each do |question|
          @outcomes.each do |outcome|
            if @quest_outcome_number[question.id].nil?
              unless question.question.downcase.index(outcome.outcome.downcase.lstrip.rstrip).nil?
                @quest_outcome_number[question.id] = @outcome_numbers[outcome.id]
              end
            end
          end
          @quest_outcome_number[question.id] = "?" if @quest_outcome_number[question.id].nil?
        end
      end
      
      flash[:badnotice] = "The entry/exit surveys are not identical, comparisons are unreliable." if (!same_length)
      # more extensive validation...
      
      @title = "Surveys for '#{@course.title}' (#{@course.term.semester})"
      @printer = params[:format].eql?('printer') rescue @printer = false
      params[:format] = 'html' if @printer
      respond_to do |format|
          format.html { 
              if @printer
                render :layout => 'printer'
              else
                render :layout => 'noright'
              end }
          format.csv  { 
            response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
            response.headers['Content-Disposition'] = "attachment; filename=#{@course.short_description}_surveys.csv"
            render :layout => false 
          }
      end
    end
  end
  
  protected :log_error

end

class TrueClass
  def yes_no
    "Yes"
  end
end
class FalseClass
  def yes_no
    "No"
  end
end
