require 'net/http'

Net::HTTP.start('localhost', 3000) do |http|
  response = http.get('/index/login?user[uniqueid]=USERNAME&user[password]=PASSWORD', 'Accept' => 'text/xml')

  cookie = response['Set-Cookie']
  session = cookie.split(/;/)[0]
  
  #puts "Code: #{response.code}" 
  #puts "Headers: #{response.header.inspect}"
  #puts "Message: #{response.message}"
  #puts "Body:\n #{response.body}"
  #puts "Cookie: #{session}"
  
  #Do something with the response.
  response = http.get('/public/api/course_template/345', {'Accept' => 'text/xml', 'Cookie' => cookie} )

  puts "Code: #{response.code}" 
  puts "Headers: #{response.header}"
  puts "Message: #{response.message}"
  puts "Body:\n #{response.body}"
end
