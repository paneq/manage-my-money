module MoneyHelper
  def print_saldo(money, user, show_empty = true)
    saldo = ''
    money.each do |currency, value|
      saldo <<  number_to_currency(value, :unit => h(currency.long_symbol), :delimeter => " ", :format => "%n %u") << "<br />"
    end
    if money.empty? && show_empty
      saldo << number_to_currency(0, :unit => h(user.default_currency.long_symbol), :delimeter => " ", :format => "%n %u")
    end
    return saldo
  end
end
