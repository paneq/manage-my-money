require 'active_record'

namespace :user do
  namespace :create do
    desc "Create user admin"
    task :admin => :environment do
      u = User.new
      u.login = 'admin'
      u.password = u.password_confirmation = '123456'
      u.email = 'admin@admin.com'
      u.save!
      u.activate!
    end
  end

  desc "Create user with given name"
  task :create => :environment do
    u = User.new
    u.login = ENV['user'] || ENV['login'] || ENV['name']
    u.password = u.password_confirmation = '123456'
    u.email = "#{u.login}@example.org"
    u.save!
    u.activate!
  end
end