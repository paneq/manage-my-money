class CreditorsController < LoansController

  layout 'main'

  # you owe him/her money
  def index
    find_loans_with_transfers_and_saldo

  end




end
