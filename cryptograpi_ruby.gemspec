require File.expand_path('lib/cryptograpi_ruby/version', __dir__)

Gem::Specification.new do |spec|
  spec.name                       = 'cryptograpi_ruby'
  spec.version                    = CryptograpiRuby::VERSION
  spec.authors                    = ['Cryptograpi']
  spec.email                      = ['support@cryptograpi.com']
  spec.summary                    = 'Cryptograpi library for ruby apps'
  spec.description                = 'Allows the communication with cryptograpi api'
  spec.homepage                   = 'https://cryptograpi.com'
  spec.license                    = 'GPL-3.0-only'
  spec.platform                   = Gem::Platform::RUBY
  spec.required_ruby_version      = '>=2.7.0'
  spec.files                      = Dir['README.md', 'LICENSE', 'CHANGELOG.md', 'lib/**/*.rb',
                                        'lib/**/*.rake', 'cryptograpi_ruby.gemspec', '.github/*.md',
                                        'Gemfile', 'Rakefile']
  spec.extra_rdoc_files           = ['README.md']
  spec.add_dependency             = 'cryptograpi_api', '~>0.1'
  spec.add_dependency             = 'rubyzip', '~> 2.3'
  spec.add_development_dependency = 'rubocop', '~> 0.60'
  spec.add_development_dependency = 'rubocop-performance', '~> 1.5'
  spec.add_development_dependency = 'rubocop-rspec', '~> 1.37'
end