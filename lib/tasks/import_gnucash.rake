namespace :import do
  namespace :gnucash do
    def parse_params
      user_name = ENV['user']
      file_name = ENV['file']
      unless user_name
        user_name = 'admin'
        puts 'No user param given'
      end

      unless file_name
        #        file_name = '/home/jarek/Desktop/cash_test'
        file_name = '/home/jarek/NetBeansProjects/other/rupert.xml'
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
      open(file_name) do |file|
        doc = Nokogiri::XML(file)
        GnucashParser.import_categories(user, doc)
      end
    end

    desc "Import transfers from gnucash"
    task :transfers => :environment do
      user, file_name = parse_params
      open(file_name) do |file|
        doc = Nokogiri::XML(file)
        GnucashParser.import_transfers(user, doc)
      end
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