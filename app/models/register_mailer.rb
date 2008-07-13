class RegisterMailer < ActionMailer::Base
  
  def sent(user, sent_at = Time.now)
    @subject    = 'Manage My Money Activation :-)'
    @body       = {:user => user, :activate_hash => user.to_hash}
    @recipients = user.email
    @from       = 'rupert@stallman.rootnode.pl'
    @sent_on    = sent_at
    @headers    = {}
  end
end
