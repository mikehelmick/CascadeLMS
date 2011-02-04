require 'net/http'
require 'net/https'

http_sess = Net::HTTP.new('my.csi.muohio.edu', 443)
http_sess.use_ssl = true

http_sess.start do |http|
  response = http.get('/index/login?user[uniqueid]=UNIQUEID&user[password]=PASSWORD', 'Accept' => 'text/xml')

  cookie = response['Set-Cookie']
  session = cookie.split(/;/)[0]
  
  #puts "Code: #{response.code}" 
  #puts "Headers: #{response.header.inspect}"
  #puts "Message: #{response.message}"
  #puts "Body:\n #{response.body}"
  #puts "Cookie: #{session}"
  
  #Do something with the response.
  response = http.get('https://my.csi.muohio.edu/course/COURSE_ID/assignments/view/ASSIGNMENT_ID', {'Accept' => 'text/xml', 'Cookie' => cookie} )

  puts "Code: #{response.code}" 
  puts "Headers: #{response.header}"
  puts "Message: #{response.message}"
  puts "Body:\n #{response.body}"
end
