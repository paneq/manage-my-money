require 'test_helper'

class LoansControllerTest < ActionController::TestCase

  def setup
    LoansController.send(:public, :find_loans_with_transfers_and_saldo)
    @controller = LoansController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

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
    debtor_transfer_item = debtor_transfer.transfer_items.first

    #none
    save_simple_transfer(:outcome => rupert.asset, :income => rupert.loan.children.second) #move money to mateusz
    save_simple_transfer(:income => rupert.asset, :outcome => rupert.loan.children.second) #mateusz gives me money back

    #my creditor
    creditor_transfer = save_simple_transfer(:income => rupert.asset, :outcome => rupert.loan.children.third)  #martga gives me some money

    #move money to bank that is not a loan category because rupert does not communicate with them via mails
    save_simple_transfer(:outcome => rupert.asset, :income => rupert.loan.children.last)

    get :test
    assert_equal [{:loan => rupert.loan.children.first, :money => Money.new(debtor_transfer_item.currency => debtor_transfer_item.value), :transfers => [debtor_transfer]}], assigns(:debtors)
    assert_not_nil assigns(:creditors)
  end
end
