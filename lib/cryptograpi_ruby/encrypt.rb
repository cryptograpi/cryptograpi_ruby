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

    def begin_encryption
      # Begins the encryption process
      # Each time this function is called, uses increments by 1
      raise 'Encryption not ready' unless @encryption_ready
      # cipher already exists
      raise 'Encryption in progress' if @encryption_started
      # Check for max uses flag
      raise 'Maximum usage exceeded' if @key['uses'] >= @key["max_uses"]

      # Increase the uses counter
      @key['uses'] += 1
      # New context and initialization vector
      @enc, @iv = Cipher.new.encryptor(@cipher, @key['raw'])
      # Pack and create a byte string
      struct = [0, Cipher::CRYPTOFLAG, @cipher[:id], @iv.length, @key['encrypted'].length].pack('CCCCn')

      @enc.auth_data = struct + @iv + @key['encrypted']
      @encryption_started = true

      # Return the encrypted object
      struct + @iv + @key['encrypted']
    end

    def update_encryption(data)
      raise 'Encryption has not started yet' unless @encryption_started

      @enc.update(data)
    end

    def finish_encryption
      raise 'Encryption not started' unless @encryption_started

      # Finalizes the encryption and adds any auth info required by the algorithm
      res = @enc.final
      if @cipher[:tag_length] != 0
        # Add the tag to the cipher text
        res += @enc.auth_tag
      end

      @encryption_started = false
      # return the encrypted result
      res
    end

    def close_encryption
      raise 'Encryption currently running' if @encryption_started

      if @key['uses'] < @key['max_uses']
        query_url = "#{endpoint}/#{@key['id']}/#{@key['session']}"
        url = "#{endpoint_base}/encryption/key/#{@key['id']}/#{@key['session']}"
        query = { actual: @key['uses'], requested: @key['max_uses'] }
        headers = Signature.headers(query_url, @host, 'patch', @papi, query, @sapi)

        response = HTTParty.patch(
          url,
          body: query.to_json,
          headers: headers
        )
        remove_instance_variable(:@key)
        @encryption_ready = false
      end
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

  # Qui e!
  def encrypt(credentials, data)
    begin
      enc = Encryption.new(credentials, 1)
      res =
        enc.begin_encryption +
        enc.update_encryption(data) +
        enc.finish_encryption
      enc.close_encryption
    rescue StandardError
      enc&.close_encryption
      raise
    end
    res
  end
end
