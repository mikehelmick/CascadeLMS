require 'ldap'
require 'ldap/control'

conn = LDAP::Conn.new( 'ldapsun1.muohio.edu', 389 )

userid='x'
password=''

bind_string = "uid=#{userid},ou=people,dc=muohio,dc=edu" 
conn.bind( bind_string, password )

page = conn.search2( bind_string, LDAP::LDAP_SCOPE_SUBTREE, '(objectclass=*)', "*" )

page[0].each do |k,v|
  puts "#{k} = #{v}"
end
