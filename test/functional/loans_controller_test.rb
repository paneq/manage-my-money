require 'test_helper'

class LoansControllerTest < ActionController::TestCase

  def setup
    LoansController.send(:public, :find_loans_with_transfers_and_saldo)
    prepare_currencies
    save_rupert
    log_rupert
  end


  test "Creditors and debetors are found properly" do
    ['jarek', 'mateusz', 'marta', 'very_important_bank'].each do |name|
      rupert.categories.create!(:name => name, :parent => rupert.loan)
    end
    rupert.loan.children[0..2].each do |category|
      category.type = LoanCategory.to_s
      category.save!
    end

    #my debtor
    debtor_transfer = save_simple_transfer(:outcome => rupert.asset, :income => rupert.loan.children.first) #move money to jarek
    debtor_transfer_item = debtor_transfer.transfer_items.find(:first, :conditions => 'value > 0')

    #none
    save_simple_transfer(:outcome => rupert.asset, :income => rupert.loan.children.second) #move money to mateusz
    save_simple_transfer(:income => rupert.asset, :outcome => rupert.loan.children.second) #mateusz gives me money back

    # creditor takes and gives money back
    save_simple_transfer(:outcome => rupert.asset, :income => rupert.loan.children.third, :currency => @dolar, :day => 5.days.ago.to_date) #move money to marta
    save_simple_transfer(:income => rupert.asset, :outcome => rupert.loan.children.third, :currency => @dolar, :day => 4.days.ago.to_date) #marta gives me money back
    #my creditor
    creditor_transfer = save_simple_transfer(:income => rupert.asset, :outcome => rupert.loan.children.third, :currency => @euro, :day => Date.today)  #martga gives me some euro money
    creditor_transfer_item = creditor_transfer.transfer_items.find(:first, :conditions => 'value < 0')
    

    #move money to bank that is not a loan category because rupert does not communicate with them via mails
    save_simple_transfer(:outcome => rupert.asset, :income => rupert.loan.children.last)

    #wewnatrz transferow normalne saldo
    # obiekt money trzyma saldo zawsze w wartosciach dodatnich.
    get :test
    assert_equal [{:loan => rupert.loan.children.first, :money => Money.new(debtor_transfer_item.currency => debtor_transfer_item.value), :transfers => [{:transfer => debtor_transfer, :saldo => Money.new(@zloty => debtor_transfer_item.value) }]}], assigns(:debtors)
    assert_equal [{:loan => rupert.loan.children.third, :money => Money.new(creditor_transfer_item.currency => -creditor_transfer_item.value), :transfers => [{:transfer => creditor_transfer, :saldo => Money.new(@euro => creditor_transfer_item.value) }]}], assigns(:creditors)
  end
end
