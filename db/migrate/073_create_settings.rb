class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.column :name, :string, :null => false
      t.column :value, :text, :null => false
      t.column :description, :text, :null => false
    end

    add_index(:settings, [:name], :unique => true)

#   Setting.create :name => 'storage_directory', :value => '/srv/www/rails/debug/shared/storage'

    Setting.create :name => 'title', :value => 'University of Life', :description => 'Main title for the site.'
    Setting.create :name => 'organization', :value => 'University of Life', :description => 'Name of the organization for which this software is installed.'

    Setting.create :name => 'email', :value => 'mike.helmick@gmail.com', :description => 'Contact email, displayed on the bottom of the page.'
    Setting.create :name => 'error_email', :value => 'mike.helmick@gmail.com', :description => 'Email address to send error reports to.   These are live reports of exceptions as they occur.'
    Setting.create :name => 'dir_link', :value => 'http://netapps.muohio.edu/phpapps/directory/?searchstring=', :description => 'Link to a directory system based on Unique IDs'

    Setting.create :name => 'external_dir', :value => '/srv/www/rails/cscourseware/shared/storage', :description => 'Local file system directory where all data for this system is stored.  It is critical that this directory, exists, has correct permissions, has enough space, and DOES NOT CHANGE.'

    Setting.create :name => 'temp_dir', :value => '/tmp', :description => 'Temporary directory for CSCW.  You can clear the contents of the directory at any time.'

    Setting.create :name => 'session_limit', :value => '1800', :description => 'Number of seconds for user sessions.'

    Setting.create :name => 'recent_items', :value => '25', :description => 'Number of recent items to show on course overview screens and RSS feeds.'

    Setting.create :name => 'enscript_command', :value => '/usr/bin/enscript', :description => 'Location of the enscript comment, used for code formatting.'

    # Require the 1.3 client - for it's XML output capabilities
    Setting.create :name => 'subversion_command', :value => '/usr/local/bin/svn', :description => 'The Subversion command line location.'

    # either ldap or basic
    #authtype: basic
    Setting.create :name => 'authtype', :value => 'basic', :description => "Authentication type may be 'ldap' or 'basic'."
  
    # the setting below need to be filled in if LDAP is being used
    #ldapserver: 127.0.0.1
    Setting.create :name => 'ldapserver', :value => 'ldapsun1.muohio.edu', :description => 'LDAP Server Name (if using LDAP authentication)'
    Setting.create :name => 'ldap_dc', :value => 'dc=muohio,dc=edu', :description => 'LDAP Directory Context'
    Setting.create :name => 'ldap_ou', :value => 'ou=people', :description => 'LDAP Object'
    Setting.create :name => 'ldap_search', :value => 'uid', :description => 'LDAP Search field'

    Setting.create :name => 'ldap_port', :value => '389', :description => 'LDAP Port, SSL is usually 636, non-SSL is usually 389.'
    Setting.create :name => 'ldap_ssl', :value => 'false', :description => "Use SSL encryption for LDAP, 'true' or 'false'."

    Setting.create :name => 'ldap_field_uid', :value => 'uid', :description => 'LDAP field that unique IDs are pulled from'
    Setting.create :name => 'ldap_field_nickname', :value => 'eduPersonNickname', :description => 'LDAP field that preferred (nickname) is pulld from'
    Setting.create :name => 'ldap_field_firstname', :value => 'givenName', :description => 'LDAP field that first names are pulled from'
    Setting.create :name => 'ldap_field_middlename', :value => 'muohioeduMiddleName', :description => 'LDAP field that middle names are pulled from'
    Setting.create :name => 'ldap_field_lastname', :value => 'sn', :description => 'LDAP field that surnames are pulled from'
    Setting.create :name => 'ldap_field_affiliation', :value => 'muohioeduAffiliation', :description => 'LDAP field that instuition affiliation is fulled from'
    Setting.create :name => 'ldap_field_personaltitle', :value => 'personalTitle', :description => 'LDAP field that titles (Mr, Ms, Dr) are pulled from'
    Setting.create :name => 'ldap_field_email', :value => 'mail', :description => 'LDAP field containing email addresses'
    Setting.create :name => 'ldap_field_officehours', :value => 'muohioeduHours', :description => 'Office hours LDAP field'
    Setting.create :name => 'ldap_field_phone', :value => 'telephoneNumber', :description => 'Telephone number LDAP field'

    Setting.create :name => 'instructor_affiliation', :value => 'Faculty', :description => 'Affiliation value from LDAP that indicates faculty affiliation'

    # auto enroll
    # Must have LDAP enabled & this info must be available via LDAP
    Setting.create :name => 'enable_auto_enroll', :value => 'true', :description => 'Enable Auto Enrollment, must have LDAP authentication and course registration numbers (from Banner Web)'

    Setting.create :name => 'ldap_faculty_crn', :value => 'muohioeduCurrentTeachingCRN', :description => 'Courses being taught by a faculty member, from LDAP'
    Setting.create :name => 'ldap_faculty_desc', :value => 'muohioeduCurrentTeachingSubjectNumber', :description => 'Description of courses being taught by a faculty member, from LDAP'
    Setting.create :name => 'ldap_student_crn', :value => 'muohioeduCurrentCourseCRN', :description => 'Course CRNs of courses a stuent is enrolled in, from LDAP'
    Setting.create :name => 'ldap_student_desc', :value => 'muohioeduCurrentCourseSubjectNumber', :description => 'Description of courses a student is enrolled in, from LDAP'
    
    ## our format is Year Term(2 digit) and a 5 digit course number
    ## with the first 6 digits fully identifying the term
    ## Any format of Y T N will work, but you can disable auto enrol or customize
    Setting.create :name => 'crn_format', :value => 'YYYYTTNNNNN', :description => 'Our format is Year, Term(2 digit), and a 5 digit course number.   The first 6 digits fully identifying the term.  Any format of Y T N will work, but you can disable auto enrol or customize'

    Setting.create :name => 'default_subjects', :value => 'CSA MTH MIS IMS', :description => 'Default subjects for automatic course population, need to customize lib_crnloader.rb for your school.'

    ## Daily Turn-in limit
    Setting.create :name => 'turnin_limit', :value => '3', :description => 'Default daily turnin limit'
    
    ## Auto Grading
    # PRODUCTION
    Setting.create :name => 'ruby', :value => '/usr/local/bin/ruby', :description => 'Location of the Ruby interpreter for external calls.'
    Setting.create :name => 'java', :value => '/usr/lib/java/bin/java', :description => 'Location of Java for external calls (1.5 or higher required)'
    Setting.create :name => 'javac', :value => '/usr/lib/java/bin/javac', :description => 'Location of the Java compiler for external calls (1.5 or higher required)'
    Setting.create :name => 'ant', :value => '/usr/bin/ant', :description => 'Location of ANT for external calls'

    # DEVELOPMENT
    #ruby: /usr/local/bin/ruby
    #java: /usr/bin/java 
    #javac: /usr/bin/javac
    #ant: /usr/bin/ant

    Setting.create :name => 'pmd_main', :value => 'edu.muohio.csa.cscourseware.CheckStyle', :description => 'Main class for PMD - do not change.'
    Setting.create :name => 'pmd_libs', :value => 'jakarta-oro-2.0.8.jar jaxen-1.1-beta-10.jar pmd-3.9.jar xercesImpl-2.6.2.jar xmlParserAPIs-2.6.2.jar checkStyle.jar asm-3.0.jar backport-util-concurrent.jar', :description => 'Jar files to pull in when running PMD. do not change.'
    Setting.create :name => 'banned_java', :value => 'java.io.File java.io.FileInputStream java.io.FileOutputStream java.io.FileReader java.io.FileWriter System.setIn System.setOut System.setErr System.loadLibrary System.setSecurityManager System.load Runtime.getRuntime java.io.*;', :description => 'Strings to disallow in Java code.  Separated by a space'
    
    Setting.create :name => 'settings_reload', :value => '300', :description => 'Settings reload frequence (seconds).  Since settings are cached on a per-thread basis, the settings may need to be refreshed from time to time.   Set this to a very high number if your settings are stable. (Default is every 5 minutes)'
    
  end

  def self.down
    drop_table :settings
  end
end
