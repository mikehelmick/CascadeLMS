class GithubServer < ActiveRecord::Base
  
  def set_defaults
    self.name = 'github.com'
    self.api_endpoint = 'https://www.github.com/api/v3'
    self.web_endpoint = 'https://www.github.com/'
  end
  
end
