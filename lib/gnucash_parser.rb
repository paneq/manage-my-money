require 'nokogiri'
require 'collections/sequenced_hash'

class GnuCashParseError < StandardError
end

class GnucashParser
  GNUCASH_NAMESPACES =  {
    'gnc' => 'http://www.gnucash.org/XML/gnc',
    'act' => 'http://www.gnucash.org/XML/act',
    'book' => 'http://www.gnucash.org/XML/book',
    'cd' => 'http://www.gnucash.org/XML/cd',
    'cmdty' => 'http://www.gnucash.org/XML/cmdty',
    'price' => 'http://www.gnucash.org/XML/price',
    'slot' => 'http://www.gnucash.org/XML/slot',
    'split' => 'http://www.gnucash.org/XML/split',
    'sx' => 'http://www.gnucash.org/XML/sx',
    'trn' => 'http://www.gnucash.org/XML/trn',
    'ts' => 'http://www.gnucash.org/XML/ts',
    'fs' => 'http://www.gnucash.org/XML/fs',
    'bgt' => 'http://www.gnucash.org/XML/bgt',
    'recurrence' => 'http://www.gnucash.org/XML/recurrence',
    'lot' => 'http://www.gnucash.org/XML/lot',
    'cust' => 'http://www.gnucash.org/XML/cust',
    'job' => 'http://www.gnucash.org/XML/job',
    'addr' => 'http://www.gnucash.org/XML/addr',
    'owner' => 'http://www.gnucash.org/XML/owner',
    'taxtable' => 'http://www.gnucash.org/XML/taxtable',
    'tte' => 'http://www.gnucash.org/XML/tte',
    'employee' => 'http://www.gnucash.org/XML/employee',
    'order' => 'http://www.gnucash.org/XML/order',
    'billterm' => 'http://www.gnucash.org/XML/billterm',
    'bt-days' => 'http://www.gnucash.org/XML/bt-days',
    'bt-prox' => 'http://www.gnucash.org/XML/bt-prox',
    'invoice' => 'http://www.gnucash.org/XML/invoice',
    'entry' => 'http://www.gnucash.org/XML/entry',
    'vendor' => 'http://www.gnucash.org/XML/vendor'
  }

  class << self

    # result format:
    # { :categories => {:in_file => X, :added => X, :merged => X, :errors => ['Asd', 'dfg']}
    #   :transfers => {:in_file => X, :added => X, :errors => ['Asd', 'dfg']}
    # }
    #
    #
    def parse(content, user)
      doc = Nokogiri::XML(content)
      result = {}
      result[:categories] = import_categories(user, doc)
      result[:transfers] = import_transfers(user, doc)
      result
    rescue GnuCashParseError
      raise
    rescue Exception => e
      logger.error(e)
      raise GnuCashParseError.new('Nieznany błąd')
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end


    def import_categories(user, doc)
      
      result = {}
      accounts_count = doc.find('//gnc:count-data[@cd:type="account"]').inner_text.to_i

      root_category = nil
      categories = SequencedHash.new
      top_categories = {}
      logger.debug "\n==Parsing categories"
      doc.find('//gnc:account').each do |node|
        #       logger.debug "Commodity: " + node.find('act:commodity/cmdty:id').inner_text
        c = Category.new
        c.import_guid = node.find('act:id').inner_text
        c.name = node.find('act:name').inner_text
        c.description = node.find('act:description').inner_text
        c.parent_guid = node.find('act:parent').inner_text
        type = node.find('act:type').inner_text
        c.user = user
        c.imported = true

        if !root_category && type == 'ROOT'
          root_category = c
        else
          c.category_type = get_3m_category_type(type)
          categories[c.import_guid] = c
          if c.parent_guid == root_category.import_guid
            top_categories[c.category_type] ||= []
            top_categories[c.category_type] << c
          end
        end
        #        print '.'; STDOUT.flush
      end



      #kategorie poziomu głownego (parent_id == root) przeniesc do naszych odpowiednich kategorii
      #chyba ze sa tylko po jednej - wtedy je utozsamiamy bez zmiany nazwy?

      logger.debug "\n==Merging top categories"
      [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE ].each do |category_type|
        top = user.categories.top.of_type(category_type).find(:first)
        unless top_categories[category_type].blank?
          if top_categories[category_type].size > 1
            top_categories[category_type].each do |item|
              item.parent = top
              item.parent_guid = nil
            end
          elsif top_categories[category_type].size == 1
            top_gc_guid = top_categories[category_type][0].import_guid
            top.import_guid = top_gc_guid
            categories[top_gc_guid] = top
            #mozna ewentualnie podmienic nazwe i opis
          end
        end
      end

      logger.debug "\n==Parenting categories"
      categories.each_value do |cat|
        unless cat.parent_guid.nil?
          #          print '.'; STDOUT.flush
          cat.parent = categories[cat.parent_guid]
        end
      end

      saved = 0
      merged = 0
      result[:errors] = []
      logger.debug "\n==Saving categories"
      categories.each_value do |cat|
        existing_cat = user.categories.find_by_import_guid(cat.import_guid)
        unless existing_cat
          #          print '.'; STDOUT.flush
          new_record = cat.new_record?
          if cat.save
            #            print '.'; STDOUT.flush
            if new_record
              saved += 1
            else
              merged += 1
            end

          else
            result[:errors] << ["Kategoria: '#{cat.name}' - ", cat.errors.full_messages.to_sentence]
          end
        end
      end
      logger.debug "\nSaved #{saved} categories from #{accounts_count}"

      result[:in_file] = accounts_count - 1 #because of ROOT category
      result[:added] = saved
      result[:merged] = merged

      return result
    end


    def import_transfers(user, doc)
      result = {}
      transaction_count = doc.find('//gnc:count-data[@cd:type="transaction"]').inner_text.to_i
      saved = 0
      logger.debug "\n==Parsing and saving transfers"
      result[:errors] = []
      doc.find('//gnc:transaction').each do |node|
        multi_currency_transfer = false
        t = Transfer.new
        t.user = user
        t.import_guid = node.find('trn:id').inner_text
        date = node.find('trn:date-posted/ts:date').inner_text
        t.day = Date.parse date
        t.description = node.find('trn:description').inner_text

        currency_name = node.find('trn:currency/cmdty:id').inner_text
        #        currency = Currency.find(:first, :conditions => ['long_symbol = ? AND (user_id IS NULL OR user_id = ?)', currency_name, user.id])
        currency = find_or_create_currency(currency_name, user)

        node.find('trn:splits/trn:split').each do |split|
          ti = TransferItem.new
          ti.import_guid = split.find('split:id').inner_text
          category_guid = split.find('split:account').inner_text
          ti.category = user.categories.find_by_import_guid(category_guid)
          ti.description = split.find('split:memo').inner_text
          value_str = split.find('split:value').inner_text
          value = parse_value(value_str)

          value_str = split.find('split:quantity').inner_text
          quantity = parse_value(value_str)

          if (value == quantity)
            ti.value = value
          else
            multi_currency_transfer = true
            break
          end

          ti.currency = currency
          t.transfer_items << ti
        end

        if multi_currency_transfer
          result[:errors] << ["#{t.day} #{t.description}: transakcje wielowalutowe nie są obsługiwane"]
          next
        end
        
        if t.save
          #          print '.'
          saved += 1
        else
          #          print 'x'
          #          logger.debug t.errors.full_messages

          result[:errors] << ["#{t.day} #{t.description}: ", t.errors.full_messages.to_sentence]

          t.transfer_items.each do |ti|
            #            logger.debug ti.errors.full_messages
            result[:errors] << ["#{t.day} #{t.description}, element: #{ti.description} ",ti.errors.full_messages.to_sentence] unless ti.errors.blank?

          end



        end
        #        STDOUT.flush

      end
      logger.debug "\nSaved #{saved} transfers from #{transaction_count}"
      result[:in_file] = transaction_count
      result[:added] = saved

      return result
    end



    protected

    if defined?(Nokogiri)
      class Nokogiri::XML::Element
        def find(what)
          xpath(what, GnucashParser::GNUCASH_NAMESPACES)
        end
      end

      class Nokogiri::XML::Document
        def find(what)
          xpath(what, GnucashParser::GNUCASH_NAMESPACES)
        end
      end
    end

    def get_3m_category_type(gnucash_type)
      case gnucash_type
      when 'ASSET', 'CASH', 'BANK','STOCK', 'MUTUAL' then :ASSET
      when 'INCOME' then :INCOME
      when 'EXPENSE' then :EXPENSE
      when 'LIABILITY', 'CREDIT', 'PAYABLE', 'RECEIVABLE' then :LOAN
      when 'EQUITY' then :BALANCE
      else nil
      end
    end

    def find_or_create_currency(long_symbol, user)
      #      long_symbol = long_symbol[0..2]
      new_currency = ( Currency.for_user(user).find_by_long_symbol(long_symbol) || Currency.new(:all => long_symbol.upcase, :user => user) )

      if new_currency.new_record?
        new_currency.save!
      end

      new_currency

    end

    def parse_value(value_str)
      value = nil
      if value_str =~ /(-?\d*)\/(\d*)/
        value = $1.to_f / $2.to_f
      else
        logger.debug "Problems parsing #{value_str} value"
      end
      return value
    end

  end
end