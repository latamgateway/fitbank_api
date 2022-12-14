# typed: strict
# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'

module FitBankApi
  module Pix
    # In order to use PIX we need to set the limits for transactions.
    # This class wrappes the API to get and set PIX transaction limits.
    # Documentation:
    # * Get limit: https://dev.fitbank.com.br/reference/260, https://dev.fitbank.com.br/docs/5-limit-management
    # * Set limit: https://dev.fitbank.com.br/reference/261, https://dev.fitbank.com.br/docs/5-limit-management
    # @note In production you would also have to send an email to FitBank in
    #   order to set the limits.
    # @todo Implement other all limits. Only daily_amount_limit is implemented. This is low priority as the API
    #   for setting limits is not used on prod and in the sandbox it's broken.
    class AccountLimit
      extend T::Sig

      PIXOUT_OPERATION_TYPE = T.let(40, Integer)
      private_constant :PIXOUT_OPERATION_TYPE

      # All different limit types which the API can set
      class LimitType < T::Enum
        extend T::Sig

        enums do
          # Limits the PIX transactions during the day e.g. 6AM and 8PM
          Daily = new
          # Limits the PIX transactions during the night e.g. 8PM and 6AM
          Overnight = new
          # Limits each individual PIX transaction. But also takes into account
          # the daily and overnight limits.
          SingleTransaction = new
        end

        sig { returns(Integer) }
        def to_i
          case self
          when Daily then 0
          when Overnight then 3
          when SingleTransaction then 4
          else
            T.absurd(self)
          end
        end
      end

      # Limit subtypes
      class LimitSubtype < T::Enum
        extend T::Sig

        enums do
          # Limits the quantity of PIX transactions being made. Does not care about
          # the total sum of money being trasfered.
          Quantity = new
          # Limits the total sum of money being trasfered.
          Amount = new
        end

        sig { returns(Integer) }
        def to_i
          case self
          when Quantity then 0
          when Amount then 1
          else
            T.absurd(self)
          end
        end
      end

      sig do
        params(
          credentials: FitBankApi::Entities::Credentials,
          bank_info: FitBankApi::Entities::BankInfo,
          base_url: String
        ).void
      end
      # Create a wrapper used to set limits for PIX transactions.
      # @param [FitBankApi::Entities::Credentials] credentials The credentials for the user which is
      #   going to set the limits
      # @param [FitBankApi::Entities::BankInfo] bank_info Bank info of the account for which the limit
      #   is going to be set
      # @param [String] base_url Base url to the FtiBank API
      def initialize(
        credentials:,
        bank_info:,
        base_url:
      )
        @credentials = credentials
        @bank_info = bank_info
        @limit_setter_url = T.let(
          URI.join(base_url, 'main/execute/ChangeAccountOperationLimit'), URI::Generic
        )
        @limit_getter_url = T.let(
          URI.join(base_url, 'main/execute/GetAccountOperationLimit'), URI::Generic
        )
      end

      sig { params(daily_limit: Integer).void }
      # Make an API call to set the daily limit for all PIX payments. The total sum of PIX payments
      # should not exceed the daily limit.
      # @param [Integer] daily_limit The daily limit for all PIX payments
      # @raise [FitBankApi::Errors::BaseApiError]
      def update_daily_amount_limit(daily_limit)
        payload = generate_set_limit_payload(
          type: LimitType::Daily,
          subtype: LimitSubtype::Amount,
          min_value: 0,
          max_value: daily_limit
        )
        FitBankApi::Utils::HTTP.post!(@limit_setter_url, payload, @credentials)
      end

      sig { returns(Integer) }
      # Make API call to get the limit of for the sum of all PIX payments.
      # @raise [FitBankApi::Errors::BaseApiError]
      # @return [Integer] The maximal daily limit
      def daily_amount_limit
        payload = generate_get_limit_payload(type: LimitType::Daily, subtype: LimitSubtype::Amount)
        response_body = FitBankApi::Utils::HTTP.post!(@limit_getter_url, payload, @credentials)
        Integer(response_body[:MaxLimit])
      end

      private

      sig do
        params(
          type: LimitType,
          subtype: LimitSubtype,
          min_value: Integer,
          max_value: Integer
        ).returns(T::Hash[Symbol, T.untyped])
      end
      # There are 3 types of limits. All of them are set via the same API call. A parameter in
      # the payload describes the limit being set. This function generates the whole payload.
      # @param [LimitType] type The type of the limit see #LimitType
      # @param [LimitSubtype] subtype The subtype of the limit @see SublimitType
      # @param [Integer] min_value Minimum value to initiate a PixOut transaction
      #   based on type conditions
      # @param [Integer] max_value Maximum value to initiate a PixOut transaction
      #   based on type conditions
      # return [Hash] Hash representing the payload for setting PixOut limit
      def generate_set_limit_payload(type:, subtype:, min_value:, max_value:)
        {
          Method: 'ChangeAccountOperationLimit',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          TaxNumber: @credentials.cnpj,
          Bank: @bank_info.bank_code,
          BankBranch: @bank_info.bank_agency,
          BankAccount: @bank_info.bank_account,
          BankAccountDigit: @bank_info.bank_account_digit,
          OperationType: PIXOUT_OPERATION_TYPE,
          Type: type.to_i,
          SubType: subtype.to_i,
          MinLimitValue: min_value,
          MaxLimitValue: max_value
        }
      end

      sig do
        params(
          type: LimitType,
          subtype: LimitSubtype
        ).returns(T::Hash[Symbol, T.untyped])
      end
      # There are 3 types of limits. All of them are get via the same API call. A parameter in
      # the payload describes the limit being retrieved. This function generates the whole payload.
      # @param [LimitType] type The type of the limit @see LimitType
      # @param [LimitSubtype] subtype The subtype of the limit @see SublimitType
      # return [Hash] Hash representing the payload for getting PixOut limit
      def generate_get_limit_payload(type:, subtype:)
        {
          Method: 'GetAccountOperationLimit',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          TaxNumber: @credentials.cnpj,
          Bank: @bank_info.bank_code,
          BankBranch: @bank_info.bank_agency,
          BankAccount: @bank_info.bank_account,
          BankAccountDigit: @bank_info.bank_account_digit,
          OperationType: PIXOUT_OPERATION_TYPE,
          Type: type.to_i,
          SubType: subtype.to_i
        }
      end
    end
  end
end
