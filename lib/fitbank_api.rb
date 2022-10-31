# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'

Dir.glob('fitbank_api/**/*.rb', base: __dir__).each do |filepath|
  require_relative filepath
end

# This module will contain all functionalities used to wrap FitBank REST API
module FitBankApi
  extend T::Sig
  BASE_URL = T.let(ENV.fetch('BASE_URL', 'https://sandboxapi.fitbank.com.br').freeze, String)
end
