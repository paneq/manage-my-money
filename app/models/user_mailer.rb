class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Dokonaj aktywacji konta'
  
    @body[:url]  = "http://#{APP_DOMAIN}/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Twoje konto zostało aktywowane!'
    @body[:url]  = "http://#{APP_DOMAIN}/"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "robert.pankowecki@gmail.com"
      @subject     = "[co-do-grosza.pl] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
