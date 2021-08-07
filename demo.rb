require_relative 'lib/cryptograpi_ruby'

CryptograpiRuby.config do |c|
  c.api_token = '123'
  c.project_id = '345'
end


puts CryptograpiRuby.api_token
puts CryptograpiRuby.project_id
