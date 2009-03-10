namespace :backup do
  task :database => :environment do
    backup_path = ENV['backup_path']
    raise "backup_path was not given" if backup_path.nil?

    db_configuration = ActiveRecord::Base.configurations[RAILS_ENV]
    system "export PGPASSWORD=#{db_configuration['password']} && pg_dump -h #{db_configuration['host']} -U #{db_configuration['username']} #{db_configuration['database']} | gzip > #{backup_path}/#{RAILS_ENV}.sql.gz"
    system "export PGPASSWORD=bad_password_haha"
  end
end
