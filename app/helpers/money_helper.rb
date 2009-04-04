module MoneyHelper
  def print_saldo(money, user)
    saldo = ''
    money.each do |currency, value|
      saldo <<  number_to_currency(value, :unit => currency.long_symbol, :delimeter => " ", :format => "%n %u") << "<br />"
    end
    if money.empty?
      saldo << number_to_currency(0, :unit => user.default_currency.long_symbol, :delimeter => " ", :format => "%n %u")
    end
    return saldo
  end
end
