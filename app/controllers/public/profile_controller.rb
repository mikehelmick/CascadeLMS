class Public::ProfileController < ApplicationController
  
  def view
    load_profile(params)
    profilename = @user_profile.user.display_name rescue @user.display_name
    @title = "Profile for #{profilename}"
    @breadcrumb = Breadcrumb.new
    @breadcrumb.public_access = true
  end
end
