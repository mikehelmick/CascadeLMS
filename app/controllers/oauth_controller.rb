require 'HTTParty'
require 'net/http'
require 'uri'

class OauthController < ApplicationController
  before_filter :ensure_logged_in
  
  def callback
    code = params[:code]
    state = params[:state].split('-')

    githubServerId = state[0]
    course = Course.find(state[1].to_i)
    assignment = Assignment.find(state[2].to_i)

    gitHubServer = GithubServer.find(githubServerId.to_i)

    query = {:body => {'client_id' => "#{gitHubServer.client_id}", 'client_secret' => "#{gitHubServer.secret_key}", 'code' => "#{code}"}}
    # Make the post request, to get the authorization token.
    result = HTTParty.post("#{gitHubServer.web_endpoint}login/oauth/access_token", query)
    if (!result.index('error').nil?)
      return github_oauth_redirect(course, assignment, @user)
    end
    
    results = Rack::Utils.parse_nested_query(result)
    puts "#{results.inspect}"
    # Save this down in the authrizations
    
    auth = GithubAuthorization.new
    auth.user = @user
    auth.github_server = gitHubServer
    auth.access_token = results['access_token']
    
    if !auth.save
      flash[:badnotice] = "There was an error authorizing access to #{gitHubServer.web_endpoint}"
    else
      flash[:notice] = "Successfully authorized access to #{gitHubServer.web_endpoint}"
    end
    redirect_to :controller => '/assignments', :action => 'view', :course => course, :id => assignment, :assignment => nil
  end
end
