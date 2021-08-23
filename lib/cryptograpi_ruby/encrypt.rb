require 'active_support/all'
require 'httparty'
require 'rb-readline'
require 'webrick'
require_relative './cipher'
require_relative './signature'

module Cryptograpi
  class Encryption
    def initialize(creds, uses)
      raise 'Some credentials are missing' unless validate_credentials(creds)

      @papi = creds.access_key_id
      @sapi = creds.signing_key
      @srsa = creds.secret_access_key
      @host = creds.host.blank? ? CRYPTOGRAPI_HOST : creds.host
      url = "#{endpoint_base}/encryption/key"
      query = { uses: uses }
      headers = Signature.headers(endpoint, @host, 'post', @papi, query, @sapi)

      @encryption_started = false
      @encryption_ready = true

      # First, ask for a key from the server.
      # If the request fails, raise a HTTPError.

      begin
        response = HTTParty.post(
          url,
          body: query.to_json,
          headers: headers
        )
      rescue HTTParty::Error
        raise 'Server Unreachable'
      end

      if response.code == WEBrick::HTTPStatus::RC_CREATED
        # Builds the key object
        @key = {}
        @key['id'] = response['key_fingerprint']
        @key['session'] = response['encryption_session']
        @key['security_model'] = response['security_model']
        @key['algorithm'] = response['security_model']['algorithm'].downcase
        @key['max_uses'] = response['max_uses']
        @key['uses'] = 0
        @key['encrypted'] = Base64.strict_decode64(response['encrypted_data_key'])

        # get the encrypted private key from response body
        encrypted_pk = response['encrypted_private_key']
        # Data key from response body
        wrapped_data_key = response['wrapped_data_key']
        # decrypt the encrypted private key using @srsa
        pk = OpenSSL::PKey::RSA.new(encrypted_pk, @srsa)
        # Decode WDK from base64 format
        wdk = Base64.strict_decode64(wrapped_data_key)
        # Use private key to decrypt the wrapped data key
        dk = pk.private_decrypt(wdk, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
        @key['raw'] = dk
        @cipher = Cipher.new.get_algorithm(@key['algorithm'])
      else
        raise "HTTPError Response: Expected 201, got #{response.code}"
      end
    end

    def begin

    end

    def update(data)

    end

    def end

    end

    def close

    end

    def endpoint
      '/api/v0/encryption/key'
    end

    def endpoint_base
      "#{@host}/api/v0"
    end

    def validate_credentials(credentials)
      !credentials.access_key_id.blank? &&
        !credentials.secret_access_key.blank? &&
        !credentials.signing_key.blank?
    end
  end

  # Check credentials are present and valid
  def validate_credentials(credentials)
    !credentials.access_key_id.blank? &&
      !credentials.secret_access_key.blank? &&
      !credentials.signing_key.blank?
  end

  # Qui è!
  def encrypt(credentials, data)
    begin
      enc = Encryption.new(credentials, 1)
      res = enc.begin + enc.update(data) + enc.end
      enc.close
    rescue StandardError
      enc&.close
      raise
    end
    res
  end
end
