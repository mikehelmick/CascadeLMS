require 'octokit'

class GitHubSession
  attr_accessor :user, :auth_error, :github_authorization
  
  # Iniailize with the OAuth credentials, this links to the server that the credential came from.
  def initialize(githubAuthorization)
    @auth_error = false;
    begin
      @client = Octokit::Client.new(
        :access_token => githubAuthorization.access_token,
        :api_endpoint => githubAuthorization.github_server.api_endpoint,
        :web_endpoint => githubAuthorization.github_server.web_endpoint,
        :auto_paginate => true
        )
      @user = @client.user
      @github_authorization = githubAuthorization
    rescue
      @auth_error = true;
      # destroy the auth object and force the user to re-auth.
      githubAuthorization.destroy()
    end

    @repos = Hash.new
    @visible_loaded = false
  end
  
  def login
    @user.login
  end
  
  # This determines the default repository name to use, based on the assignment pattern
  def resolve_repo_name(assignment)
    pattern = assignment.github_pattern
    pattern.gsub!('$githubid$',self.login)
    pattern.gsub!('$uniqueid$', @github_authorization.user.uniqueid)
    if assignment.github_organization.nil? || assignment.github_organization.eql?('')
      return pattern
    else
      return "#{assignment.github_organization}/#{pattern}"
    end
  end
  
  def owned_repositories
    user_repos = @client.repositories(login)
    prase_repo_response(user_repos)

    ownedRepos = Hash.new
    @repos.keys.each do |k|
      idx = k.index(login)
      if !idx.nil? && idx == 0
        ownedRepos[k] = @repos[k]
      end
    end
    return ownedRepos
  end
  
  def install_hooks(repository)
    
  end

  def list_commits(repository, branch = 'master')
    @client.list_commits(repository, branch)
  end
 
  def get_branch(repository, branch = 'master')
    @client.branch(repository, branch)
  end

  def get_tree(repository, shaSig)
    @client.tree(repository, shaSig, {:recursive => true})
  end

  def clone_to_dir(repository, dir)
    return true
  end

  # Load visible repositories in the context of an assignment (because it may have an organization)
  def visible_repositories(assignment)
    return @repos if @visible_loaded

    if !assignment.github_organization.nil? && !assignment.github_organization.eql?('')
      org_repos = @client.organization_repositories(assignment.github_organization, {:type => 'member'})
      prase_repo_response(org_repos)
    end
    user_repos = @client.repositories(login)
    prase_repo_response(user_repos)

    @visible_loaded = true  
    return @repos  
  end

  # Attempts to get a specific repository
  def get_repository(name)
    if @repos[name].nil?
      begin
        @repos[name] = @client.repository(name);
      rescue
        @repos[name] = false
      end
    end
    return @repos[name]
  end
  
  private
  def prase_repo_response(repo_reponse) 
    repo_reponse.each do |resp|
      @repos[resp['full_name']] = resp
    end
  end
end