require 'ldap'
require 'ldap/control'

# Performs LDAP authentication
class LdapAuthentication
  
  # settings must be a hash containing the appropriate settings
  def initialize( settings )
    @settings = settings
  end
  
  def authenticate( username, password ) 
    check_settings()
    
    begin
      # create connection
      conn = LDAP::Conn.new( @settings['ldapserver'], @settings['ldap_port'] )
      if @settings['ldap_ssl']
        conn = LDAP::SSLConn.new( @settings['ldapserver'], @settings['ldap_port'] )
      end
      
      # Bind as the user
      # build a sting like
      # uid=USERID,ou=people,dc=muohio,dc=edu
      bind_string = "#{@settings['ldap_search']}=#{username},#{@settings['ldap_ou']},#{@settings['ldap_dc']}" 
      conn.bind( bind_string, password )
    
      ## if bind isn't successful a LDAP exception is raised
      # search for the users record
      page = conn.search2( bind_string, LDAP::LDAP_SCOPE_SUBTREE, '(objectclass=*)', "*" )
    
      user = User.find(:first, :conditions => ['uniqueid = ?', username ] )
      if user.nil?
        user = create_user( page, password )
      else
        user = update_user( user, page )
      end
      # user if valid, authorized, and synced 
      return user
      
    rescue LDAP::ResultError => doh
      raise SecurityError, "Authentication error: #{doh.message}", caller
    end
    
  end
  
  # creat a new user in this system from their ldap page
  def create_user( page, password )
    user = User.new()
    user.password = password
    user.admin = 'N'
    
    update_user( user, page )
  end
  
  # refresh a user from their ldap page
  def update_user( user, page )
    # load fields from LDAP
    user.uniqueid = page[0][@settings['ldap_field_uid']][0]
    user.preferred_name = page[0][@settings['ldap_field_nickname']][0] unless page[0][@settings['ldap_field_nickname']].nil? 
    user.first_name = page[0][@settings['ldap_field_firstname']][0]
    user.middle_name = page[0][@settings['ldap_field_middlename']][0] unless page[0][@settings['ldap_field_middlename']].nil?
    user.last_name = page[0][@settings['ldap_field_lastname']][0]
    user.instructor = 'N'
    user.affiliation = page[0][@settings['ldap_field_affiliation']].join(', ')
    page[0][@settings['ldap_field_affiliation']].each do |x|
      if x.downcase.eql?( @settings['instructor_affiliation'].downcase ) 
        user.instructor = 'Y'
      end
    end
    user.personal_title = page[0][@settings['ldap_field_personaltitle']][0] unless page[0][@settings['ldap_field_personaltitle']].nil?
    user.office_hours = page[0][@settings['ldap_field_officehours']][0] unless page[0][@settings['ldap_field_officehours']].nil?
    user.phone_number = page[0][@settings['ldap_field_phone']][0] unless page[0][@settings['ldap_field_phone']].nil?
    user.email = page[0][@settings['ldap_field_email']][0]
    
    if ! user.save
      raise SecurityError, "Unable to save user: #{user.errors.full_messages.join(', ')}", caller
    end
    
    return user
  end  
  
  def check_settings
    required_field = ['ldapserver', 'ldap_dc', 'ldap_ou', 'ldap_search', 
                      'ldap_field_uid', 'ldap_field_firstname', 
                      'ldap_field_lastname', 'ldap_field_email',
                      'ldap_port', 'ldap_ssl' ]
    required_field.each do |x| 
      raise SecurityError, "LDAP configuration missing: #{x}" if @settings[x].nil? || @settings[x].eql?('')
    end
  end
  
  private :check_settings, :create_user, :update_user
  
end