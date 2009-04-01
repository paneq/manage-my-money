
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
    currency = @currencies[long_symbol] ||= ( Currency.for_user(@user).find_by_long_symbol(long_symbol) || Currency.new(:all => long_symbol.upcase, :user => @user) )

    if currency.new_record?
      currency.save!
      warnings << @warning_class.new("Aby umożliwić zaimportowanie tego transferu została stworzona nowa waluta o symbolu: #{long_symbol}", currency)
    end

    currency
  end


  def warn_similar_transfer(guid, date, amount, currency, warnings)
    previous_transfer = @user.transfers.find_by_import_guid(guid)
    unless previous_transfer
      previous_transfer = @user.
        transfers.
        find(:first,
        :joins => 'INNER JOIN transfer_items ON transfers.id = transfer_items.transfer_id',
        :conditions => ['day = ? AND transfer_items.value = ? AND transfer_items.currency_id = ?', date, amount, currency.id]) if currency
    end
    warnings << @warning_class.new('Ten transfer został już najprawdopodobniej zaimportowany', previous_transfer) if previous_transfer
  end


end
