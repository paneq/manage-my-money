
require 'nokogiri'
require 'open-uri'

class Nokogiri::XML::Element
  def find(what)
    xpath(what).inner_html
  end
end


class Nokogiri::XML::Document
  def find(what)
    xpath(what).inner_html
  end
end


class InteligoParser
  def self.parse(content, user, category)
    doc = Nokogiri::XML(content)

    operations = doc.xpath('//operation')

    bank_account_number_in_file = doc.find('//search/account')
    currencies = {}

    result = []
    types = [:income, :outcome]
    operations.each do |operation|
      id = operation['id']
      description = operation.find('description')
      order_date = operation.find('order-date').to_date
      amount = operation.xpath('amount').first

      currency_long_symbol = amount['curr']
      currencies[currency_long_symbol] ||= Currency.for_user(user).find_by_long_symbol(currency_long_symbol)
      currency = currencies[currency_long_symbol]

      amount = amount.inner_html.to_f
      item_type, other_item_type = amount > 0 ? types : types.reverse

      other_side = operation.xpath('other-side')
      other_category = nil
      unless other_side.empty?
        number = other_side.find('account')
        # other_category = user.categories.find_by_account_number(number)
      end

      puts id, order_date, amount, currency_long_symbol, "\n"

      import_guid = [bank_account_number_in_file, id].join('-')
      # TODO: sprawdzanie czy taki transfer nie byl juz zaimportowany
      t = Transfer.new(:day => order_date, :description => description, :import_guid => import_guid)
      t.transfer_items << TransferItem.new(:currency => currency, :value => amount.abs, :category => category, :transfer_item_type => item_type)
      t.transfer_items << TransferItem.new(:currency => currency, :value => amount.abs, :category => other_category, :transfer_item_type => other_item_type)
      result << {:transfer => t, :warnings => []}
    end

    return result
  end
end
