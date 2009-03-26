namespace :db do
  namespace :migrate do
    desc 'Migrates development and selenium databases and clones structure for tests and do annotate models'
    task :all do
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:test:clone_structure'].invoke
      puts `rake db:migrate RAILS_ENV=selenium` #no other way to change Rails_ENV while running  rake
      Rake::Task['annotate_models'].invoke
    end
  end
end