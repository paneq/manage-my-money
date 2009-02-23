class DebtorMailer < ActionMailer::Base

  # user => user that sends this remind
  # info = {:loan => category, :money => Money, :transfers => [ {:transfer => t, :saldo => Money}...]}
  # text => text of message for users
  # currencies => list of currencies used by user
  def remind(user, info, text, currencies)
    sbj = "[co-do-grosza.pl] Przypomnienie o aktualnym stanie zadłużenia od użytkownika #{user.login}"
    recipients    "#{info[:loan].email}"
    from          "robert.pankowecki@gmail.com"
    subject       sbj
    sent_on       Time.now
    reply_to      user.email.to_s
    content_type  "text/html"
    body          info.merge(:user => user, :subject => sbj, :currencies => currencies, :text => text)
  end

end
