# frozen_string_literal: true

require_relative 'lib/fitbank_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'fitbank_api'
  spec.version       = FitBankApi::VERSION
  spec.authors       = ['Latam Gateway']
  spec.email         = ['kimpastro@gmail.com']

  spec.summary       = 'Wrapper classes for the FitBank REST API'
  spec.description   = 'Contains classes which can be used to perform PIX payments using the FitBank REST API'
  spec.homepage      = 'https://github.com/latamgateway/fitbank_api'
  spec.required_ruby_version = '~> 2.7.6'

  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/latamgateway/fitbank_api'
  spec.metadata['changelog_uri'] = 'https://github.com/latamgateway/fitbank_api/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency('builder')
  spec.add_dependency('bundler')
  spec.add_dependency('cpf_cnpj', '~> 0.5.0')
  spec.add_dependency('rake')
  spec.add_dependency('sorbet-static-and-runtime', '~> 0.5.0')

  spec.add_development_dependency('dotenv', '~> 2.8.0')
  spec.add_development_dependency('factory_bot', '~> 6.1')
  spec.add_development_dependency('pry-byebug', '~> 3.9')
  spec.add_development_dependency('rspec', '~> 3.10')
  spec.add_development_dependency('webmock', '~> 3.18.0')
  spec.add_development_dependency('rubocop')
  spec.add_development_dependency('tapioca')
  spec.add_development_dependency('vcr', '~> 6.0')
  spec.add_development_dependency('yard')
  # spec.add_development_dependency('uuid', '~> 2.3', '>= 2.3.9')
end
