# typed: strict
# frozen_string_literal: true

require 'cpf_cnpj'
require 'securerandom'
require 'net/http'
require 'date'
require 'uri'
require 'json'

module FitBankApi
  module Pix
    # Wrapper for FitBank API used for performing manual PIX Payout
    class Payout
      extend T::Sig

      # All payment types supported for PixOut
      # @note Although the docs state that the value for manual Pix must be 0
      #   this is not true. For manual payment we must pass PixKeyType and
      #   PixKey as null. Check the comments on the payload below.
      class PaymentKeyType < T::Enum
        extend T::Sig

        enums do
          Manual = new
          PixKey = new
          StaticQrCode = new
          DynamicQrCode = new
        end

        sig { returns(Integer) }
        def to_i
          case self
          when Manual then 0
          when PixKey then 1
          when StaticQrCode then 3
          when DynamicQrCode then 4
          else
            T.absurd(self)
          end
        end
      end

      # Describes the type of bank accounts of the customers
      class AccountType < T::Enum
        extend T::Sig

        enums do
          Current = new
          Saving = new
        end

        sig { returns(Integer) }
        def to_i
          case self
          when Current then 0
          when Saving then 1
          else
            T.absurd(self)
          end
        end
      end

      sig do
        params(
          base_url: String,
          request_id: String,
          receiver_bank_info: FitBankApi::Entities::BankInfo,
          sender_bank_info: FitBankApi::Entities::BankInfo,
          credentials: FitBankApi::Entities::Credentials,
          receiver_name: String,
          receiver_document: String,
          value: BigDecimal
        ).void
      end
      # Create a manual PIX payment.
      # @param [String] base_url The base URL of the API, defining whether prod
      #   or sandbox environemt is used
      # @param [String] request_id Idempotency key generated by us. At most one request made with this key
      #   will be performed
      # @param [FitBankApi::Entities::BankInfo] receiver_bank_info The bank info for the
      #   customer receiving for the money
      # @param [FitBankApi::Entities::BankInfo] sender_bank_info The bank info for the
      #   one who sends the money
      # @param [FitBankApi::Entities::Credentials] credentials Latam credentials for FitBank
      # @param [String] receiver_name The name of the customer receiving the money
      # @param [String] receiver_document CPF/CNPJ of the customer receiving the money
      # @param [BigDecimal] value The amount of money which will be transfered
      def initialize(
        base_url:,
        request_id:,
        receiver_bank_info:,
        sender_bank_info:,
        credentials:,
        receiver_name:,
        receiver_document:,
        value:
      )
        @receiver_bank_info = receiver_bank_info
        @sender_bank_info = sender_bank_info
        @credentials = credentials
        @request_id = request_id
        @receiver_name = receiver_name
        @value = value
        @manual_payout_url = T.let(
          URI.join(base_url, 'main/execute/GeneratePixOut'), URI::Generic
        )
        if CPF.valid?(receiver_document)
          @receiver_document = T.let(CPF.new(receiver_document).stripped, String)
        elsif CNPJ.valid?(receiver_document)
          @receiver_document = T.let(CNPJ.new(receiver_document).stripped, String)
        else
          # TODO: Create custom exception
          raise 'Invalid receiver document'
        end
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      # Perform a PIX Payment. For FitBank API documentation check:
      # https://dev.fitbank.com.br/docs/3-payments and https://dev.fitbank.com.br/reference/234
      # Note the first link is high level overview and some parameters are missing. The second
      # link provides full list of parameters.
      # @raise [FitBankApi::Errors::BaseApiError] in case of an API error
      # @raise [Net::HTTPError] if the request status was not 2xx
      def call
        # All CPF/CNPJ must be stripped when using this API, no dashes, dots or slashes are
        # accepted.
        #
        # TODO: Currently if Bank or ToBank are different than "450" the API responds with error
        payload = {
          Method: 'GeneratePixOut',
          # PartnerId and BusinessUnitId are constants generated by FitBank, unique for Latam
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          # Sender Bank Data TODO: Where do we get this data?
          TaxNumber: @credentials.cnpj,
          # Receiver Bank Data
          ToTaxNumber: @receiver_document,
          ToName: @receiver_name,
          ToBank: @receiver_bank_info.bank_code,
          ToBankBranch: @receiver_bank_info.bank_agency,
          ToBankAccount: @receiver_bank_info.bank_account,
          ToBankAccountDigit: @receiver_bank_info.bank_account_digit,
          # TODO: Make this a parameter. Although the values are integers
          # the API accepts this as string.
          AccountType: AccountType::Current.to_i.to_s,
          Value: @value.to_s('F'),
          # RateValue and RateValueType are used if the partner want's to incure
          # additinoal fee. For our current setup FitBank expects this to be 0.
          RateValue: 0,
          RateValueType: 0,
          # Idempotency key generated by us. At most one request made with this key
          # will be performed
          Identifier: @request_id,
          # Optional
          Tags: [],
          # The date can be used to perform delayed payments. We pass the current
          PaymentDate: DateTime.now.strftime('%Y/%m/%d'),
          # According to the docs for manual PIX PixKey must be empty string and PixKeyType must be 4
          # This is WRONG. FitBank confirmed via chat, that if we want manual PIX we need to set
          # PixKey=null, PixKeyType=null and SearchProtocol=null. For manual PIX the Description
          # must be non-empty
          PixKey: nil,
          PixKeyType: nil,
          SearchProtocol: nil,
          Description: 'Transfer',
          CustomerMessage: 'Transfer',
          OnlineTransfer: true
        }.merge(@sender_bank_info.to_h)

        FitBankApi::Utils::HTTP.post!(@manual_payout_url, payload, @credentials)
      end
    end
  end
end
