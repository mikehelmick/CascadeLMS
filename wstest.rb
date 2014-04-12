require 'net/http'
require 'net/https'

http_sess = Net::HTTP.new('localhost', 3000)
http_sess.use_ssl = false

http_sess.start do |http|
  #response = http.get('/index/login?user[uniqueid]=UNIQUEID&user[password]=PASSWORD', 'Accept' => 'text/xml')
  
  response = http.get('/oauth/request_token?oauth_consumer_key=thLs25v1xTnHqPDRAT5lfQtmVoNbe7cmuKnbRGuJ')
  puts response.inspect
  
  body = response.body
  
  
  #cookie = response['Set-Cookie']
  #session = cookie.split(/;/)[0]

  #puts "Code: #{response.code}"
  #puts "Headers: #{response.header.inspect}"
  #puts "Message: #{response.message}"
  #puts "Body:\n #{response.body}"
  #puts "Cookie: #{session}"

  #Do something with the response.
  #response = http.get('http://localhost:3000/post/view/5', {'Accept' => 'text/xml', 'Cookie' => cookie} )

  #puts "Code: #{response.code}"
  #puts "Headers: #{response.header}"
  #puts "Message: #{response.message}"
  #puts "Body:\n #{response.body}"
end
