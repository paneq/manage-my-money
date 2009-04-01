
class BankParser

  attr_reader :content, :user, :category, :currencies, :warning_class, :result

  def initialize(content, user, category)
    @content = content
    @user = user
    @category = category
    @warning_class = Struct.new(:description, :data)
    @result = []
    @currencies = {}
  end

  
  def find_or_create_currency(long_symbol, warnings)
    long_symbol = long_symbol[0..2]
    @currencies[long_symbol] ||= ( Currency.for_user(@user).find_by_long_symbol(long_symbol) || Currency.new(:all => long_symbol.upcase, :user => @user) )

    if @currencies[long_symbol].new_record?
      @currencies[long_symbol].save!
      warnings << @warning_class.new("Aby umożliwić zaimportowanie tego transferu została stworzona nowa waluta o symbolu: #{currency_long_symbol}", currency)
    end

  end

end
