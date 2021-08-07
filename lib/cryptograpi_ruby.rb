# frozen_string_literal: true

module CryptograpiRuby
  class << self
    attr_accessor :api_token, :project_id
    # attr_writer :locales_path

    # Let's provide a straightforward way
    # to provide options, like
    # CryptograpiRuby.config do |c|
    #   c.api_token = '123'
    #   c.project_id = '345'
    # end
    def config
      yield self
    end
  end
end