class Notifier < ActionMailer::Base
  
  def send_email( addresses, text, subject, from_user )
    @recipients = from_user.email
    @bcc = addresses
    @subject = subject
    @from = "#{from_user.display_name} <#{from_user.email}>"
    
    @body[:text] = text
  end
  
  def send_email_to( addresses, text, subject, from_user ) 
    @recipients = addresses
    @bcc = [from_user.email]
    @subject = subject
    @from = "#{from_user.display_name} <#{from_user.email}>"
    
    @body[:text] = text
  end
  
  def send_create( new_user, user, link, organization )  
    @recipients = "#{new_user.display_name} <#{new_user.email}>"
    @subject = "#{subject} - Account Created - CascadeLMS"
    @from = "#{user.display_name} <#{user.email}>"
    
    @body[:link] = link
    @body[:to_user] = new_user
    @body[:from_user] = user
    @body[:organization] = organization
  end
  
  def send_recover( user, from_address, link, organization )
    @recipients = "#{user.display_name} <#{user.email}>"
    @subject = "Password Reset Request - CascadeLMS"
    @from = "#{from_address} <#{from_address}>"
    
    @body[:link] = link
    @body[:to_user] = user
    @body[:organization] = organization    
    @body[:from_address] = from_address
  end
  
end
