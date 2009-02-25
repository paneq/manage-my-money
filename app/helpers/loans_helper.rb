module LoansHelper
  def print_saldo(money)
    saldo = ''
    money.each do |currency, value|
      saldo += '<span>'
      saldo += "#{value} #{currency.long_symbol} <br />"
      saldo += '</span>'
    end
    return saldo
  end
end
