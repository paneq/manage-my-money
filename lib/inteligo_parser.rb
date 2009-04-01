
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

class InteligoParser < BankParser

  def initialize(content, user, category)
    super(content, user, category)
  end

  
  def parse
    doc = Nokogiri::XML(@content)
    operations = doc.xpath('//operation')

    bank_account_number_in_file = doc.find('//search/account')

    types = [:income, :outcome]
    operations.each do |operation|
      warnings = []

      id = operation['id']
      description = operation.find('description')
      order_date = operation.find('order-date').to_date
      amount = operation.xpath('amount').first

      currency = find_or_create_currency(amount['curr'], warnings)

      amount = amount.inner_text.to_f
      item_type, other_item_type = amount > 0 ? types : types.reverse

      other_side = operation.xpath('other-side')
      other_category = nil
      unless other_side.empty?
        number = other_side.find('account')
        other_category = @user.categories.find_by_bank_account_number(number)
      end

      import_guid = [bank_account_number_in_file, id].join('-')
      warn_similar_transfer(import_guid, order_date, amount, currency, warnings)
      

      t = Transfer.new(:day => order_date, :description => description, :import_guid => import_guid)
      t.transfer_items << TransferItem.new(:currency => currency, :value => amount.abs, :category => @category, :transfer_item_type => item_type)
      t.transfer_items << TransferItem.new(:currency => currency, :value => amount.abs, :category => other_category, :transfer_item_type => other_item_type)
      @result << {:transfer => t, :warnings => warnings}
    end

    return @result # array o hashes  [{:transfer => Transfer, :warnings => Array}, ...]
  end
end
