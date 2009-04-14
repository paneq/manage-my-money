class CreditorsController < LoansController

  # you owe him/her money
  def index
    find_loans_with_transfers_and_saldo
    @categories = @current_user.categories.map{|c| [c.id, c.name_with_indentation]}
  end


  def pay
    payer = @current_user.categories.find_by_id(params[:payer])
    creditor = @current_user.categories.find_by_id(params[:creditor])
    saldo = creditor.current_saldo.negative
    transfer = Transfer.new(:day => Date.today, :description => 'Spłata zadłużenia', :user => @current_user)
    saldo.each do |cur, val|
      transfer.transfer_items.build(:description => "Spłata zadłużenia w walucie: #{cur.long_symbol}", :category => payer, :value => val, :currency => cur)
      transfer.transfer_items.build(:description => "Spłata zadłużenia w walucie: #{cur.long_symbol}", :category => creditor, :value => -val, :currency => cur)
    end
    if transfer.save
      flash[:notice] = "Spłacono wybrane zadłużenie. Transfer z : <a href='#{category_path(payer)}'>#{payer.name}</a> do <a href='#{category_path(creditor)}'>#{creditor.name}</a>"
    else
      flash[:notice] = "Operacja nie powiodła się" #FIXME: Will not always be saved becuase of lack of conversions in multicurrency transactions.
    end
    redirect_to :back
  end

end
