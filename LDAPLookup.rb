require 'ldap'
require 'ldap/control'

#conn = LDAP::Conn.new( 'ldapsun1.muohio.edu', 389 )
conn = LDAP::SSLConn.new( 'ldapsun1.muohio.edu', 636 )


userid=''
password=''

bind_string = "uid=#{userid},ou=people,dc=muohio,dc=edu" 
conn.bind( bind_string, password )

page = conn.search2( bind_string, LDAP::LDAP_SCOPE_SUBTREE, '(objectclass=*)', "*" )

page[0].each do |k,v|
 if k.eql?('muohioeduCurrentTeachingCRN') || k.eql?('muohioeduCurrentTeachingSubjectNumber') ||  k.eql?('muohioeduCurrentCourseCRN') 
    puts "#{k} = #{v.join(',')}"
  else
    puts "#{k} = #{v}"
  end
end
