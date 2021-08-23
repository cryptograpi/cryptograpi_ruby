# frozen_string_literal: true

require 'configparser'
require 'rb-readline'
require_relative './host.rb'

module Cryptograpi
  class Info
    def initialize(access_key_id, secret_access_key, signing_key, host)
      @access_key_id      = access_key_id
      @secret_access_key  = secret_access_key
      @signing_key        = signing_key
      @host               = host
    end

    def set_attrs
      return OpenStruct.new(
        access_key_id:      @access_key_id
        secret_access_key:  @secret_access_key
        signing_key:        @signing_key
        host:               @host
      )
    end
  end

  # Loads and reads a credential file or uses default info
  class ConfigCredentials < Info
    def initialize(configuration_file, profile)
      # Check if the file exists
      if !configuration_file.nil? && !File.exist?(configuration_file)
        raise RuntimeError, "There is an error finding or reading the #{configuration_file} file"
      end

      if configuration_file.nil?
        configuration_file = '~/.cryptograpi/credentials'
      end

      if File.exist?(File.expand_path(configuration_file))
        @credentials = load_configuration_file(configuration_file, profile)
      end
    end

    def get_attrs
      return @credentials
    end

    def load_configuration_file(file, profile)
      config = ConfigParser.new(File.expand_path(file))

      # Dicts for profiles
      p  = {}
      d  = {}

      # If there is a default profile, get it
      if config['default'].present?
        d = config['default']
      end

      if !d.key?('SERVER')
        d['SERVER'] = Cryptograpi::CRYPTOGRAPI_HOST
      end

      # If there is a supplied profile, get it
      if config[profile].present?
        p = config[profile]
      end

      # Use the supplied profile. Otherwise use default
      access_key_id = p.key?('ACCESS_KEY_ID') ? p['ACCESS_KEY_ID'] : d['ACCESS_KEY_ID']
      secret_access_key = p.key?('SECRET_ACCESS_KEY') ? p['SECRET_ACCESS_KEY'] : d['SECRET_ACCESS_KEY']
      signing_key = p.key?('SIGNING_KEY') ? p['SIGNING_KEY'] : d['SIGNING_KEY']
      host = p.key?('SERVER') ? p['SERVER'] : d['SERVER']

      # Sanitizing the host variable to always include https 
      if !host.include?('http://') && !host.include?('https://')
        host = 'https://' + host
      end

      return Info.new(access_key_id, secret_access_key, signing_key, host).set_attrs
    end
  end

  # Credentials can be explicitly set or
  # use info from ENV Variables
  class Credentials < Info
    def initialize(papi, sapi, srsa, host)
      @access_key_id = papi.present? ? papi : ENV['CRYPTOGRAPI_ACCESS_KEY_ID']
      @secret_access_key = sapi.present? ? sapi : ENV['CRYPTOGRAPI_SECRET_ACCESS_KEY']
      @signing_key = srsa.present? ? srsa : ENV['CRYPTOGRAPI_SIGNING_KEY']
      @host = host.present? ? host : ENV['CRYPTOGRAPI_SERVER']
    end

    @creds = Info.new(@access_key_id, @secret_access_key, @signing_key, @host).set_attrs

    def get_attrs
      return @creds
    end
  end
end
