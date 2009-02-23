class DebtorsController < LoansController

  layout 'main'

  #he/she owes you money
  def index
    find_loans_with_transfers_and_saldo
  end

  #send reminds for people
  def remind

  end

end
