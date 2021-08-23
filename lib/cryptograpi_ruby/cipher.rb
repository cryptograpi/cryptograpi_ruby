require 'active_support/all'
require 'openssl'

module Cryptograpi
  class Cipher
    def set_algorithm
      @algorithm = {
        'aes-128-gcm' => {
          id: 0,
          algorithm: OpenSSL::Cipher::AES128,
          mode: OpenSSL::Cipher.new('aes-128-gcm'),
          key_length: 16,
          iv_length: 12,
          tag_length: 16
        },
        'aes-256-gcm' => {
          id: 1,
          algorithm: OpenSSL::Cipher::AES256,
          mode: OpenSSL::Cipher.new('aes-256-gcm'),
          key_length: 32,
          iv_length: 12,
          tag_length: 16
        }
      }
    end

    def find_algorithm(id)
      set_algorithm.each do |k, v|
        return k if v[:id] == id
      end
      'unknown'
    end

    def get_algorithm(name)
      set_algorithm[name]
    end

    def encryptor(obj, key, init_vector = nil)
      # The 'key' parameter is a byte string that contains the key
      # for this encryption operation.
      # If there is an, correct length, initialization vector (init_vector)
      # then it is used. If not, the function generates one.
      raise 'Invalid key length' if key.length != obj[:key_length]

      raise 'Invalid initialization vector length' if !init_vector.nil? && init_vector.length != obj[:init_vector_length]

      cipher = obj[:mode]
      cipher.encrypt
      cipher.key = key
      init_vector = cipher.random_init_vector

      [cipher, init_vector]
    end

    def decryptor(obj, key, init_vector)
      raise 'Invalid key length' if key.length != obj[:key_length]

      raise 'Invalid initialization vector length' if !init_vector.nil? && init_vector.length != obj[:init_vector_length]

      cipher = obj[:mode]
      cipher.decrypt
      cipher.key = key
      cipher.init_vector = init_vector

      cipher
    end
  end
end
