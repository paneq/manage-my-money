#code from http://quotedprintable.com/2007/11/16/seed-data-in-rails
namespace :db do
  desc "Load seed fixtures (from db/fixtures) into the current environment's database."
  task :seed_yml => :environment do
    require 'active_record/fixtures'
    Dir.glob(RAILS_ROOT + '/db/fixtures/*.yml').each do |file|
      Fixtures.create_fixtures('db/fixtures', File.basename(file, '.*'))
    end
  end

  task :seed_rb => :environment do
    Dir.glob(RAILS_ROOT + '/db/fixtures/*.rb').each do |file|
      require file
      populator_name = File.basename(file, ".rb")
      populator_name.camelize.constantize.send(:populate)
    end
  end

end