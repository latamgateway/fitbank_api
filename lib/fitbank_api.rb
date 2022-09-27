# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require 'fitbank_api/pix/payout'
require 'fitbank_api/entities/bank_info'
require 'fitbank_api/entities/credentials'

# This module will contain all functionalities used to wrap FitBank REST API
module FitBankApi
  extend T::Sig
  BASE_URL = T.let(ENV.fetch('BASE_URL', 'https://sandboxapi.fitbank.com.br').freeze, String)
end
