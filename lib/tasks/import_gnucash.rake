require 'active_record'
#require 'hpricot'
require 'nokogiri'
require 'collections/sequenced_hash'

namespace :import do
  namespace :gnucash do
    def gnucash_namespaces
      {
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
    end

    class Nokogiri::XML::Element
      def find(what)
         xpath(what, gnucash_namespaces)
      end
    end

    class Nokogiri::XML::Document
      def find(what)
         xpath(what, gnucash_namespaces)
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


    def parse_params
      user_name = ENV['user']
      file_name = ENV['file']
      unless user_name
        user_name = 'admin'
        puts 'No user param given'
      end

      unless file_name
#        file_name = '/home/jarek/Desktop/cash_test'
        file_name = '/home/jarek/Desktop/rupert.xml'
        puts 'No file param given'
      end

      puts "Importing data from '#{file_name}' for '#{user_name}'"

      user = User.find_by_login user_name

      if user.nil?
        puts "No such user: '#{user_name}' \nAborting."
        exit
      end

      puts "Found user #{user}"

      unless File.exist?(file_name)
        puts "No such file: '#{file_name}' \nAborting."
        exit
      end
      
      return user, file_name
    end


    desc "Import categories from gnucash"
    task :categories => :environment do
      
      user, file_name = parse_params

      doc = Nokogiri::XML(open(file_name))

      accounts_count = doc.find('//gnc:count-data[@cd:type="account"]').inner_html.to_i


      root_category = nil
      categories = SequencedHash.new
      top_categories = {}
      puts "\n==Parsing categories"
      doc.find('//gnc:account').each do |node|
#       puts "Commodity: " + node.find('act:commodity/cmdty:id').inner_html
        c = Category.new
        c.import_guid = node.find('act:id').inner_html
        c.name = node.find('act:name').inner_html
        c.description = node.find('act:description').inner_html
        c.parent_guid = node.find('act:parent').inner_html
        type = node.find('act:type').inner_html
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
        print '.'; STDOUT.flush
      end



        #kategorie poziomu głownego (parent_id == root) przeniesc do naszych odpowiednich kategorii
        #chyba ze sa tylko po jednej - wtedy je utozsamiamy bez zmiany nazwy?
      puts "\n==Merging top categories"
      [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE ].each do |category_type|
        top = user.categories.top.of_type(category_type).find(:first)
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

      puts "\n==Parenting categories"
      categories.each_value do |cat|
        unless cat.parent_guid.nil?
          print '.'; STDOUT.flush
          cat.parent = categories[cat.parent_guid]
        end
      end

      saved = 0
      puts "\n==Saving categories"
      categories.each_value do |cat|
        existing_cat = user.categories.find_by_import_guid(cat.import_guid)
        unless existing_cat
          print '.'; STDOUT.flush
          if cat.save
            print '.'; STDOUT.flush
            saved += 1
          else
            print 'x'; STDOUT.flush
          end
        end
      end
      puts "\nSaved #{saved} categories from #{accounts_count}"
    end


    desc "Import transfers from gnucash"
    task :transfers => :environment do
      user, file_name = parse_params

      doc = Nokogiri::XML(open(file_name))
      transaction_count = doc.find('//gnc:count-data[@cd:type="transaction"]').inner_html.to_i
      saved = 0
      puts "\n==Parsing and saving transfers"
      doc.find('//gnc:transaction').each do |node|
        t = Transfer.new
        t.user = user
        t.import_guid = node.find('trn:id').inner_html
        date = node.find('trn:date-posted/ts:date').inner_html
        t.day = Date.parse date
        t.description = node.find('trn:description').inner_html

        currency_name = node.find('trn:currency/cmdty:id').inner_html
        currency = Currency.find(:first, :conditions => ['long_symbol = ? AND (user_id IS NULL OR user_id = ?)', currency_name, user.id])

        node.find('trn:splits/trn:split').each do |split|
          ti = TransferItem.new
          ti.import_guid = split.find('split:id').inner_html
          category_guid = split.find('split:account').inner_html
          ti.category = user.categories.find_by_import_guid(category_guid)
          ti.description = split.find('split:memo').inner_html
          value_str = split.find('split:value').inner_html
          if value_str =~ /(-?\d*)\/(\d*)/
            ti.value = $1.to_f / $2.to_f
          else
            puts "Problems parsing #{value_str} value"
          end
          ti.currency = currency
          t.transfer_items << ti
        end


        if t.save
          print '.'
          saved += 1
        else
          print 'x'
          puts t.errors.full_messages
          t.transfer_items.each do |ti|
            puts ti.errors.full_messages
          end
        end
        STDOUT.flush
        
      end
      puts "\nSaved #{saved} transfers from #{transaction_count}"
    end

    desc "Import categories and transfers from gnucash"
    task :all => [:categories, :transfers] do
    end


    desc "Delete categories and transfers imported from gnucash"
    task :remove_all => [:remove_transfers, :remove_categories] do
    end


    desc "Delete transfers imported from gnucash"
    task :remove_transfers => :environment do
      user, file_name = parse_params
      
      transfers = user.transfers.find :all,
            :conditions => ["import_guid IS NOT NULL", true]
      deleted = 0
      puts "\n==Removing transfers"
      transfers.each do |tr|
        print '.'; STDOUT.flush
        if tr.delete
          deleted += 1
        end

      end
      puts "\nDeleted #{deleted} transfers from #{transfers.size}"

    end

    desc "Delete categories imported from gnucash"
    task :remove_categories => :environment do
      user, file_name = parse_params

      categories = user.categories.find :all,
            :conditions => ["import_guid IS NOT NULL AND imported = ?", true],
            :order => 'categories.lft',
            :select => 'id'
      puts "\n==Removing categories"
      deleted = 0
      categories.each do |id|
        category = Category.find_by_id id
        catch(:indestructible) do
          print '.'; STDOUT.flush
          category.destroy
          deleted += 1
        end
      end

      puts "\n==Removing top categories import_guid"
      user.categories.top.each do |category|
        category.import_guid = nil
        category.save!
      end

      puts "\nDeleted #{deleted} categories from #{categories.size}"


      puts

    end


end

end