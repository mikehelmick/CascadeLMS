require 'net/http'
require 'net/https'

http_sess = Net::HTTP.new('localhost', 3000)
http_sess.use_ssl = false

http_sess.start do |http|
  response = http.get('/index/login?user[uniqueid]=admin&user[password]=Rbqw123e', 'Accept' => 'text/xml')

  cookie = response['Set-Cookie']
  session = cookie.split(/;/)[0]
  
  #puts "Code: #{response.code}" 
  #puts "Headers: #{response.header.inspect}"
  #puts "Message: #{response.message}"
  #puts "Body:\n #{response.body}"
  #puts "Cookie: #{session}"
  
  #Do something with the response.
  response = http.get('http://localhost:3000/course/1', {'Accept' => 'text/xml', 'Cookie' => cookie} )

  puts "Code: #{response.code}" 
  puts "Headers: #{response.header}"
  puts "Message: #{response.message}"
  puts "Body:\n #{response.body}"
end
