class LoansController < ApplicationController

  before_filter :login_required

  def test
    find_loans_with_transfers_and_saldo
    render :text => 'test'
  end if ENV["RAILS_ENV"] == 'test'


  protected


  def find_loans_with_transfers_and_saldo
    @currencies = Currency.for_user(self.current_user).to_a
    @loans = []
    @creditors = [] #table of hashes {:loan => category, :money => Money, :transfers => [ {:transfer => t, :saldo => Money}...]}
    @debtors = []

    @current_user.categories.people_loans.each do |loan|
      saldo = loan.current_saldo(:default)
      next if saldo.empty?
      credit = saldo.negative
      debet = saldo.positive
      @loans << loan
      transfers = loan.recent_unbalanced
      @debtors << {:loan => loan, :money => debet, :transfers => transfers} unless debet.empty?
      @creditors << {:loan => loan, :money => credit, :transfers => transfers} unless credit.empty?
    end
  end

end
