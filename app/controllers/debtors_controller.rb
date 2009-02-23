class DebtorsController < LoansController

  layout 'main'

  #he/she owes you money
  def index
    find_loans_with_transfers_and_saldo
  end

  #send reminds for people
  def remind
    # {:loan => category, :money => Money, :transfers => [ {:transfer => t, :saldo => Money}...]}
    find_loans_with_transfers_and_saldo #TODO: optimize to be taken from cache

    @debtors.delete_if {|info| params["send-#{info[:loan].id}"].nil? }
    empty_emails, @debtors = @debtors.partition{|info| info[:loan].email.blank?}
    @errors = empty_emails.map{|info| "Kategoria: <b>#{info[:loan].name}</b> posiada pusty adres e-mail. Wysłanie przypomnienia było niemożliwe. "}
    @debtors.each {|info| info[:transfers] = nil if params["include-transfers-#{info[:loan].id}"].nil? }
    @sent = []
    @debtors.each do |info|
      begin
        DebtorMailer.deliver_remind(self.current_user, info, params[:text], @currencies)
        @sent << info[:loan]
      rescue Exception => e
        @errors << "Nie udało się wysłać wiadomości na adres: #{info[:loan].email}" unless ENV['RAILS_ENV'] == 'development'
        raise e if ENV['RAILS_ENV'] == 'development'
      end
    end
    flash[:notice] = (@errors.empty? ? 'Wszystkie wiadomości wysłano pomyślnie' : 'Wystąpiły błędy w czasie wysyłania wiadomości.')
  end

end
