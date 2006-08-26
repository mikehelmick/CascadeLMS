class Notifier < ActionMailer::Base
  
  def send_email( addresses, text, subject, from_user )
    @recipients = from_user.email
    @bcc = addresses
    @subject = subject
    @from = "#{from_user.display_name} <#{from_user.email}>"
    
    @body[:text] = text
  end
  
end
