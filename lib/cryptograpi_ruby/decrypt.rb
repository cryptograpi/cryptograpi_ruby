require 'active_support/all'
require 'httparty'
require 'rb-readline'
require 'webrick'
require_relative './cipher'
require_relative './encrypt'
require_relative './signature'

module Cryptograpi
  class Decryption
    def initialize(creds)
      raise 'Some credentials are missing' unless validate_credentials(creds)

      @papi = creds.access_key_id
      @sapi = creds.signing_key
      @srsa = creds.secret_access_key
      @host = creds.host.blank? ? CRYPTOGRAPI_HOST : creds.host

      @encryption_started = false
      @encryption_ready = true
    end

    def endpoint
      '/api/v0/encryption/key'
    end

    def endpoint_base
      "#{@host}/api/v0"
    end

    def begin_decryption
    end

    def update_decryption
    end

    def finish_decryption
    end

    def close_decryption
    end
  end

  def decrypt(creds, data)
    begin
      dec = Decryption.new(creds)
      res = dec.begin_decryption + dec.update_decryption + dec.finish_decryption
      dec.close_decryption
    rescue StandardError
      dec&.close_decryption
      raise
    end

    res
  end

end
