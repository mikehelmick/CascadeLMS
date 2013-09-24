
# Handles all authentication internal to this application
class BasicAuthentication
  
  def initialize
  end
  
  # takes in a username and password and
  # returns a user object if valid or raises a SecurityError
  def authenticate( username, password, logger = nil )
    logger.info("Using basic auth for #{username}.") unless logger.nil?
    u = User.find(:first, :conditions => ['uniqueid = ?', username.downcase ] )
    raise SecurityError, "Username/Password combination invalid", caller unless !u.nil? && u.valid_password?(password) 
    return u
  end
  
end
