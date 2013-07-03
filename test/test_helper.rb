ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...

  # Creates a test user, with a valid password, can be used for login tests.
  def create_test_user(uniqueid, firstname, lastname, email, password,
        instructor = false, admin = false, auditor = false)
    user = User.new(:uniqueid => uniqueid, :first_name => firstname,
        :last_name => lastname, :email => email)
    user.instructor = instructor
    user.admin = admin
    user.auditor = auditor
    user.password = 'first'
    unless user.save
      raise "Unable to create test user #{uniqueid}"
    end
    user.update_password(password)
    user.save
    return user
  end

  def create_student(uniqueid)
    create_test_user(uniqueid, uniqueid, uniqueid, "#{uniqueid}@cascadelms.org", uniqueid)
  end

  def create_instructor(uniqueid)
    create_test_user(uniqueid, uniqueid, uniqueid, "#{uniqueid}@cascadelms.org", uniqueid, true)
  end

  def create_admin(uniqueid)
    create_test_user(uniqueid, uniqueid, uniqueid, "#{uniqueid}@cascadelms.org", uniqueid, true, true)
  end

  # Meant for integration tests, performs a login
  def login(uniqueid)
    get '/'
    assert_response :success

    post_via_redirect '/index/login', :user => {:uniqueid => uniqueid, :password => uniqueid}
    assert_equal '/home', path
  end
end
