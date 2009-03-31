
require 'nokogiri'
require 'open-uri'

class Nokogiri::XML::Element
  def find(what)
    xpath(what).inner_text
  end
end


class Nokogiri::XML::Document
  def find(what)
    xpath(what).inner_text
  end
end


class Nokogiri::XML::NodeSet
  def find(what)
    xpath(what).inner_text
  end
end

class InteligoParser
  def self.parse(content, user, category)

    warning_class = Struct.new(:description, :data)

    doc = Nokogiri::XML(content)
    operations = doc.xpath('//operation')

    bank_account_number_in_file = doc.find('//search/account')
    currencies = {}

    result = []
    types = [:income, :outcome]
    operations.each do |operation|
      warnings = []

      id = operation['id']
      description = operation.find('description')
      order_date = operation.find('order-date').to_date
      amount = operation.xpath('amount').first

      currency_long_symbol = amount['curr']
      currencies[currency_long_symbol] ||= Currency.for_user(user).find_by_long_symbol(currency_long_symbol)
      currency = currencies[currency_long_symbol]
      if currency.nil?
        currency = Currency.new(:all => currency_long_symbol[0..2].upcase, :user => user)
        currency.save!
        currencies[currency_long_symbol] = currency
        warnings << warning_class.new("Aby umożliwić zaimportowanie tego transferu została stworzona nowa waluta o symbolu: #{currency_long_symbol}", currency)
      end

      amount = amount.inner_html.to_f
      item_type, other_item_type = amount > 0 ? types : types.reverse

      other_side = operation.xpath('other-side')
      other_category = nil
      unless other_side.empty?
        number = other_side.find('account')
        other_category = user.categories.find_by_bank_account_number(number)
      end

      import_guid = [bank_account_number_in_file, id].join('-')

      previous_transfer = user.transfers.find_by_import_guid(import_guid)
      unless previous_transfer
        previous_transfer = user.
          transfers.
          find(:first,
          :joins => 'INNER JOIN transfer_items ON transfers.id = transfer_items.transfer_id',
          :conditions => ['day = ? AND transfer_items.value = ? AND transfer_items.currency_id = ?', order_date, amount, currency.id]) if currency
      end
      warnings << warning_class.new('Ten transfer został już najprawdopodobniej zaimportowany', previous_transfer) if previous_transfer

      t = Transfer.new(:day => order_date, :description => description, :import_guid => import_guid)
      t.transfer_items << TransferItem.new(:currency => currency, :value => amount.abs, :category => category, :transfer_item_type => item_type)
      t.transfer_items << TransferItem.new(:currency => currency, :value => amount.abs, :category => other_category, :transfer_item_type => other_item_type)
      result << {:transfer => t, :warnings => warnings}
    end

    return result
  end
end
