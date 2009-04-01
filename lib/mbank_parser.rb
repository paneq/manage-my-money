class MbankParser < BankParser

  DO_NOTHING = Proc.new{|*args|}.freeze
  DO_TRUE = Proc.new{|*args| true}.freeze
  DO_FALSE = Proc.new{|*args| false}.freeze


  CONDITIONS = [
    Proc.new do |prev, current|
      prev && prev.first =~ /Waluta/
    end,

    DO_TRUE,

    Proc.new do |prev, current|
      prev && prev.first =~ /Numer rachunku/
    end,

    DO_TRUE,

    Proc.new do |prev, current|
      prev &&
        prev.first =~ /Data operacji/ &&
        prev.second =~ /Data księgowania/ &&
        prev.third =~ /Opis operacji/ &&
        prev.fourth =~ /Kwota/ &&
        prev.fifth =~ /Saldo po operacji/
    end,

    Proc.new do |prev, current|
      current.to_s =~ /Saldo/
    end,

    DO_FALSE
  ]



  ACTIONS = [
    DO_NOTHING,

    Proc.new do |prev, current, instance|
      instance.currency = instance.find_or_create_currency(current.first, [])
    end,

    DO_NOTHING,

    Proc.new do |prev, current, instance|
      instance.account = current.first
    end,

    DO_NOTHING,

    Proc.new do |prev, current, instance|
      types = [:income, :outcome]
      date = current.first.to_date
      description = current.third.strip
     
      amount = Kernel.Float current.fourth.gsub(/ +/,'').gsub(',','.')
      item_type, other_item_type = amount > 0 ? types : types.reverse
      amount = amount.abs
      
      account_number = description.match(/\d{26}$/)
      account = nil

      if account_number
        account_number = account_number.to_s
        account = instance.user.categories.find_by_bank_account_number(account_number)
        description.gsub!(account_number, '') if account
      end

      transfer = Transfer.new(:day => date, :description => description)
      transfer.transfer_items.build(:transfer_item_type => item_type, :value => amount, :currency => instance.currency, :category => instance.category)
      transfer.transfer_items.build(:transfer_item_type => other_item_type, :value => amount, :currency => instance.currency, :category => account)
      instance.result <<  {:transfer => transfer, :warnings => []}
    end,

    DO_NOTHING
  ]


  STATES = [
    :WAITING_FOR_CURRENCY,
    :GETTING_CURRENCY,
    :WAITING_FOR_ACCOUNT_NUMBER,
    :GETTING_ACCOUNT_NUMBER,
    :WAITING_FOR_TRANSACTION_HEADERS,
    :GETTING_TRANSACTIONS,
    :WAITING_FOR_FILE_END
  ]

  attr_accessor :currency, :account

  def initialize(content, user, category)
    super(content, user, category)
  end


  def parse
    @content = Iconv.conv('UTF-8', 'WINDOWS-1250', @content)
    previous = nil

    conditions, actions, states = CONDITIONS.clone, ACTIONS.clone, STATES.clone
    condition, action, state = conditions.shift, actions.shift, states.shift

    FasterCSV.parse(@content, :col_sep => ';', :skip_blanks => true) do |row|
      if condition.call(previous, row)
        condition, action, state = conditions.shift, actions.shift, states.shift
      end
      action.call(previous, row, self)
      previous = row
    end

    return @result # array o hashes  [{:transfer => Transfer, :warnings => Array}, ...]
  end


end

