class GithubAuthorization < ActiveRecord::Base
  belongs_to :user
  belongs_to :github_server
end
