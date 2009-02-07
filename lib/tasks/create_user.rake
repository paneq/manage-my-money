require 'active_record'

namespace :user do
  namespace :create do
    desc "Create user admin"
    task :admin => :environment do
      u = User.new
      u.login = 'admin'
      u.password = u.password_confirmation = '123456'
      u.email = 'admin@admin.com'
      #u.active = true
      u.save!
      u.activate!
    end
  end
end