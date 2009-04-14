module FileSiteKeys
  ATTRIBUTES = [
    :session_key,
    :session_secret,
    :memcached_port,
    :memcached_key,
    :rest_auth_site_key,
    :rest_auth_digest_stretches,
    :app_domain,
    :app_name,
    :app_email
    ]
  
  ATTRIBUTES.freeze

  ATTRIBUTES.each do |meth|
    attr_accessor meth
  end

  def default_keys_configuration_file
    File.join(root_path, 'config', 'site_keys.yml')
  end

  def default_example_keys_configuration_file
    File.join(root_path, 'config', 'site_keys_example.yml')
  end

  def apply_file_keys
    require 'erb'
    raise "File does not exist: #{default_keys_configuration_file}. You can copy it from #{default_example_keys_configuration_file} and then edit it." unless File.exist?(default_keys_configuration_file)
    settings = YAML::load(ERB.new(IO.read(default_keys_configuration_file)).result)
    settings = settings[environment]

    ATTRIBUTES.each do |meth|
      meth = meth.to_s
      value = settings[meth]

      if (value.nil? || ( value.is_a?(String) && value.strip.empty? ) )
        raise <<ERR
config.#{meth} is not set properly.
Current type: #{value.class}.
Current value: #{value.inspect}.
Use config/site_keys.yml to set it or environment.rb
ERR
      end

      send(meth.to_s + '=', value)
    end
    
  end
end