# typed: strict
# frozen_string_literal: true

module FitBankApi
  module Entities
    # Holds data for a bank. The data is used to make transfer to
    # this bank and account. Used by the manual PIX transfer API.
    class BankInfo
      extend T::Sig

      sig { returns(String) }
      attr_accessor :bank_code, :bank_account, :bank_agency, :bank_account_digit, :account_type

      sig { params(bank_code: String, bank_agency: String, bank_account: String, bank_account_digit: String, account_type: String).void }
      def initialize(
        bank_code:,
        bank_agency:,
        bank_account:,
        bank_account_digit: '',
        account_type: ''
      )
        @bank_code = bank_code
        @bank_agency  = bank_agency
        @bank_account = bank_account
        @bank_account_digit = bank_account_digit
        @account_type = account_type
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      # Get a hash representation of the bank info. This can be directly
      # merged into API endpoint payloads which require the bank info
      # @return [Hash]
      def to_h
        {
          Bank: @bank_code,
          BankBranch: @bank_agency,
          BankAccount: @bank_account,
          BankAccountDigit: @bank_account_digit,
          AccountType: @account_type
        }
      end

      sig { params(other: FitBankApi::Entities::BankInfo).returns(T::Boolean) }
      def ==(other)
        @bank_code == other.bank_code \
          && @bank_agency == other.bank_agency \
          && @bank_account == other.bank_account \
          && @bank_account_digit == other.bank_account_digit \
          && @account_type == other.account_type
      end
    end
  end
end
