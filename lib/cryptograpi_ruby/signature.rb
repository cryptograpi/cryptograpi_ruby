# frozen_string_literal: true

require 'active_support/all'

module Cryptograpi
  # HTTP authentication for our platform
  class Signature
    def self.headers(endpoint, host, http_method, papi, query, sapi)

      # Request Target (http_method path?query)
      req_target = "#{http_method} #{endpoint}"

      # Unix time for signature creation
      created_at = Time.now.to_i

      # We hash the body of the HTTP message. Even if it's empty
      ha_sha512 = OpenSSL::Digest.new('SHA512')
      ha_sha512 << JSON.dump(query)
      digest = "SHA-512=#{Base64.strict_encode64(ha_sha512.digest)}"

      # Initialize headers
      header_signature = {}
      header_signature['user-agent'] = "cryptograpi_ruby/#{Cryptograpi::VERSION}"
      header_signature['content-type'] = 'application/json'
      header_signature['(request-target'] = req_target
      header_signature['date'] = sign_date
      header_signature['host'] = get_host(host)
      header_signature['(created)'] = created_at
      header_signature['digest'] = digest
      headers = %w[content-type date host (created) (request-target) digest]

      # Calculate HMAC including the headers
      hmac = OpenSSL::HMAC.new(sapi, OpenSSL::Digest.new('SHA512'))
      headers.each do |header|
        hmac << "#{header}: #{header_signature[header]}\n" if header_signature.key?(header)
      end

      header_signature.delete('(created)')
      header_signature.delete('(request-target)')
      header_signature.delete('(host)')

      # Build the final signature
      header_signature['signature'] = "keyId=\"#{papi}\""
      header_signature['signature'] += ', algorithm="hmac-sha512"'
      header_signature['signature'] += ", created=#{created_at}"
      header_signature['signature'] += ", headers=#{headers.join(' ')}\""
      header_signature['signature'] += ', signature='
      header_signature['signature'] += Base64.strict_encode64(hmac.digest)
      header_signature['signature'] += '"'

      header_signature
    end

    def self.sign_date
      "#{DateTime.now.in_time_zone('GMT').strftime('%a, %d %b %Y')} #{DateTime.now.in_time_zone('GMT').strftime('%H:%M:%S')} GMT"
    end

    def self.get_host(host)
      uri = URI(host)
      ret = uri.hostname.to_s
      ret += ":#{uri.port}" if /:[0-9]/.match?(host)
      ret
    end
  end

end
