# frozen_string_literal: true

require File.expand_path('lib/cryptograpi_ruby/version', __dir__)

Gem::Specification.new do |spec|
  spec.name                       = 'cryptograpi_ruby'
  spec.version                    = CryptograpiRuby::VERSION
  spec.authors                    = ['Cryptograpi']
  spec.email                      = ['support@cryptograpi.com']
  spec.summary                    = 'Cryptograpi library for ruby apps'
  spec.description                = 'Allows the communication with cryptograpi api'
  spec.homepage                   = 'https://cryptograpi.com'
  spec.license                    = 'MIT'
  spec.platform                   = Gem::Platform::RUBY
  spec.required_ruby_version      = '>=2.7.0'
  spec.files                      = Dir['README.md', 'LICENSE', 'CHANGELOG.md', 'lib/**/*.rb',
                                        'lib/**/*.rake', 'cryptograpi_ruby.gemspec', '.github/*.md',
                                        'Gemfile', 'Rakefile']
  spec.extra_rdoc_files           = ['README.md']
  # spec.add_dependency             'cryptograpi_api', '~>0.1'
  spec.add_dependency             'rubyzip', '~> 2.3'
  spec.add_development_dependency 'rubocop', '~> 1.18'
  spec.add_development_dependency 'rubocop-performance', '~> 1.11'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.4'
  spec.add_development_dependency 'codecov', '~> 0.1'
  spec.add_development_dependency 'dotenv', '~> 2.5'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'simplecov', '~> 0.16'
  spec.add_development_dependency 'vcr', '~> 6.0'

  # Use an embedded rails app for testing
  spec.add_development_dependency 'rails', '~> 6.1'
  spec.add_development_dependency 'rspec-rails', '~> 4.0'



  spec.add_runtime_dependency     'activesupport', '~> 6.1'
  spec.add_runtime_dependency     'configparser', '>=0.1'
  spec.add_runtime_dependency     'httparty', '~> 0.18'
  spec.add_runtime_dependency     'rb-readline', '~> 0.5'
  spec.add_runtime_dependency     'tzinfo-data', '>= 1'
  spec.add_runtime_dependency     'webrick', '~> 1.7'
end
