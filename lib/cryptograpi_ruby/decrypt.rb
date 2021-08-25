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

      @decryption_started = false
      @decryption_ready = true
    end

    def begin_decryption
      raise ' Decryption is not ready' unless @decryption_ready

      raise ' Decryption already started' if @decryption_started

      raise 'Decryption already in progress' if @key.present? && @key.key?('dec')

      @decryption_started = true
      @data = ''
    end

    def update_decryption(data)
      raise ' Decryption is not started' unless @decryption_started

      # Act as a buffer for data
      @data += data

      # If there is no key or dec member of key, a header is still being built
      if !@key.present? || !@key.key?('dec')
        struct_length = [1, 1, 1, 1, 1].pack('CCCCn').length
        packed_struct = @data[0...struct_length]

        # Does the buffer contain enough of the header to determine
        # the lengths of the initialization vector and the key?
        if @data.length > struct_length
          version, flags, algorithm_id, iv_length, key_length = packed_struct.unpack('CCCCn')

          raise 'Invalid encryption header' if (version != 0) || ((flags & ~Cipher::CRYPTOFLAG) != 0)

          if @data.length > struct_length + iv_length + key_length
            # Extract the initialization vector
            iv = @data[struct_length...iv_length + struct_length]
            # Extract the encrypted key
            enc_key = @data[struct_length + iv_length..key_length + struct_length + iv_length]
            # Remove the header from the buffer
            @data = @data[struct_length + iv_length + key_length..-1]

            # Generate a key identifier
            hash_sha512 = OpenSSL::Digest.new('SHA512')
            hash_sha512 << enc_key
            client_id = hash_sha512.digest

            if @key.present?
              close if @key['client_id'] != client_id
            end

            unless @key.present?
              url = endpoint_base + '/decrypt/key'
              query = { encrypted_data_key: Base64.strict_encode64(enc_key) }
              headers = Signature.headers(endpoint, @host, 'post', @papi, query, @sapi)

              response = HTTParty.post(
                url,
                body: query.to_json,
                headers: headers
              )

              if response.code == WEBrick::HTTPStatus::RC_OK
                @key = {}
                @key['finger_print'] = response[key_fingerprint]
                @key['client_id'] = client_id
                @key['session'] = response['encryption_session']

                # Get the cipher name
                @key['algorithm'] = Cipher.new.find_algorithm(algorithm_id)

                encrypted_private_key = response['encrypted_private_key']
                # Decrypt WDK from base64
                wdk = Base64.strict_decode64(wrapped_data_key)
                # Use private key to decrypt the wdk
                dk = private_key.private_decrypt(wdk, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)

                @key['raw'] = dk
                @key['uses'] = 0
              else
                raise "HTTPError response: Expected 201 got #{response.code}"
              end
            end

            # If the key object exists, create a new decryptor.
            # Increment the key usage
            if @key.present?
              @cipher = Cipher.new.get_algorithm(@key['algorithm'])
              @key['dec'] = Cipher.new.decryptor(@cipher, @key['raw'], iv)

              if (flags & Cipher::CRYPTOFLAG) != 0
                @key['dec'].auth_data = packed_struct + iv + enc_key
              end
              @key['uses'] += 1
            end
          end
        end
      end

      plain_text = ''
      if @key.present? && @key.key?('dec')
        size = @data.length - @cipher[:tag_length]
        if size.positive?
          plain_text = @key['dec'].update(@data[0..size - 1])
          @data = @data[size..-1]
        end
        plain_text
      end
    end

    def finish_decryption
      raise 'Decryption is not started' unless @decryption_started

      # Update maintains tag-size bytes in the buffer
      # When this function is called, all data must already be
      # in the decryption object
      sz = @data.length - @cipher[:tag_length]

      raise 'Invalid Tag!' if sz.negative?

      if sz.zero?
        @key['dec'].auth_tag = @data
        begin
          plain_text = @key['dec'].final
          # Delete the context
          @key.delete('dec')
          # Return the plain text
          @decryption_started = false
          plain_text
        rescue Exception
          print 'Invalid cipher data or tag!'
          ''
        end
      end
    end

    def close_decryption
      raise 'Decryption currently running' if @decryption_started

      # Reset the decryption object
      if @key.present?
        if @key['uses'].positive?
          query_url = "#{endpoint}/#{@key['finger_print']}/#{@key['session']}"
          url = "#{endpoint_base}/decryption/key/#{@key['finger_print']}/#{@key['session']}"
          query = { uses: @key['uses'] }
          headers = Signature.headers(query_url, @host, 'patch', @papi, query, @sapi)

          response = HTTParty.patch(
            url,
            body: query.to_json,
            headers: headers
          )

          remove_instance_variable(:@data)
          remove_instance_variable(:@key)
        end
      end
    end

    def endpoint
      '/api/v0/encryption/key'
    end

    def endpoint_base
      "#{@host}/api/v0"
    end

  end

  def decrypt(creds, data)
    begin
      dec = Decryption.new(creds)
      res = dec.begin_decryption + dec.update_decryption(data) + dec.finish_decryption
      dec.close_decryption
    rescue StandardError
      dec&.close_decryption
      raise
    end

    res
  end

end
