# typed: strict
# frozen_string_literal: true

module FitBankApi
  module Entities
    # Holds data for a bank. The data is used to make transfer to
    # this bank and account. Used by the manual PIX transfer API.
    class BankInfo
      extend T::Sig

      sig { returns(String) }
      attr_accessor :bank_code, :bank_account, :bank_agency, :bank_account_digit

      sig { params(bank_code: String, bank_agency: String, bank_account: String, bank_account_digit: String).void }
      def initialize(
        bank_code:,
        bank_agency:,
        bank_account:,
        bank_account_digit: ''
      )
        @bank_code = bank_code
        @bank_agency  = bank_agency
        @bank_account = bank_account
        @bank_account_digit = bank_account_digit
      end
    end
  end
end
