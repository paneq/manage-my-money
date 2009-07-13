
# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Configuration.class_eval do
  include FileSiteKeys #defined in preinitializer
end


Rails::Initializer.run do |config|
  config.apply_file_keys
  #FIXME: Make it DRY:
  REST_AUTH_SITE_KEY = config.rest_auth_site_key
  REST_AUTH_DIGEST_STRETCHES = config.rest_auth_digest_stretches
  MEMCACHED_PORT = config.memcached_port
  APP_DOMAIN = config.app_domain
  APP_NAME = config.app_name
  APP_EMAIL = config.app_email
  SSL_REQUIRED = config.ssl_required
  SSL_ALLOWED = config.ssl_allowed
  
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  config.frameworks -= [:active_resource]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/sweepers )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :key => config.session_key,
    :secret      => config.session_secret
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :user_observer

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  config.i18n.default_locale = :pl
  config.cache_store = :mem_cache_store, "127.0.0.1:#{config.memcached_port}", { :namespace => "#{config.memcached_key}_manage_my_money_#{config.environment}" }

  #db connection
  config.gem 'postgres'

  # backgroundrb
  config.gem 'packet'
  config.gem 'chronic'

  #parsing xml
  config.gem 'collections', :lib => 'collections'
  config.gem 'collections', :lib => 'collections/sequenced_hash'
  config.gem 'nokogiri', :version => '1.2.3'

  #pagination
  config.gem 'mislav-will_paginate', :version => '~> 2.3', :lib => 'will_paginate', :source => 'http://gems.github.com'

  #parsinv csv files from mbank
  config.gem 'fastercsv', :version => '~> 1.4.0'

  #sending mails from google.
  config.gem 'ambethia-smtp-tls', :lib => 'smtp-tls', :version => '~> 1.1.2'

  #whenever for configuring cron tasks.
  config.gem 'javan-whenever', :lib => false, :source => 'http://gems.github.com'

  # Required only for project development
  #  config.gem 'flay'
  #  config.gem 'flog'
  #  config.gem 'railroad', :version => '0.5'
  #  config.gem 'reek'
  #  config.gem 'roodi'
  #  config.gem 'rspec-rails', :lib => 'spec'
  #  config.gem 'rspec-rails', :lib => 'spec/rails'
  #  config.gem 'jscruggs-metric_fu', :lib => 'metric_fu', :source => 'http://gems.github.com'
  #  config.gem 'mergulhao-rcov', :lib => 'rcov', :source => 'http://gems.github.com'
  #  config.gem 'mergulhao-rcov', :lib => 'rcov/rcovtask', :source => 'http://gems.github.com'
  #  config.gem 'mocha'
  #  
  #  TODO: Selenium in proper version
  
  config.after_initialize do
    class Date
      include DateExtensions
    end

  end

end

#ExceptionNotifier.exception_recipients = %w(your_mail@example.org) if defined?(ExceptionNotifier)
