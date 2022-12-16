# typed: strict

require 'cpf_cnpj'
require 'securerandom'
require 'net/http'
require 'date'
require 'uri'
require 'json'

module FitBankApi
  module Pix
    # Wrapper for FitBank API used for creating a Payment Order
    class PaymentOrder
      extend T::Sig

      sig do
        params(
          base_url: String,
          request_id: String,
          sender_bank_info: FitBankApi::Entities::BankInfo,
          credentials: FitBankApi::Entities::Credentials,
          receiver_name: String,
          receiver_document: String,
          value: BigDecimal,
          payment_date: String,
          receiver_pix_key: T.nilable(String),
          receiver_bank_info: T.nilable(FitBankApi::Entities::BankInfo)
        ).void
      end
      # Create a payment order.
      # @param [String] base_url The base URL of the API, defining whether prod
      #   or sandbox environemt is used
      # @param [String] request_id Idempotency key generated by us. At most one request made with this key
      #   will be performed
      # @param [FitBankApi::Entities::BankInfo] sender_bank_info The bank info for the
      #   one who sends the money
      # @param [FitBankApi::Entities::Credentials] credentials Latam credentials for FitBank
      # @param [String] receiver_name The name of the customer receiving the money
      # @param [String] receiver_document CPF/CNPJ of the customer receiving the money
      # @param [BigDecimal] value The amount of money which will be transfered
      # @param [String] payment_date Date when the payment order will be settled; format: YYYY/MM/DD
      # @param [String] receiver_pix_key The PIX key of the customer receiving for the money.
      #   If not present, receiver bank info will be used instead.
      # @param [FitBankApi::Entities::BankInfo] receiver_bank_info The bank info for the
      #   customer receiving for the money
      def initialize(
        base_url:,
        request_id:,
        sender_bank_info:,
        credentials:,
        receiver_name:,
        receiver_document:,
        value:,
        payment_date:,
        receiver_pix_key: nil,
        receiver_bank_info: nil
      )
        @sender_bank_info = sender_bank_info
        @credentials = credentials
        @request_id = request_id
        @receiver_name = receiver_name
        @value = value.to_f
        @payment_date = payment_date
        @payment_order_url = T.let(
          URI.join(base_url, 'main/execute/GeneratePaymentOrder'), URI::Generic
        )
        @get_payment_order_url = T.let(
          URI.join(base_url, 'main/execute/GetPaymentOrder'), URI::Generic
        )
        @receiver_account_info = receiver_pix_key ? { PixKey: receiver_pix_key } : receiver_bank_info.to_h

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
      # Create a Payment Order. For FitBank API documentation check:
      # https://dev.fitbank.com.br/docs/brazil and https://dev.fitbank.com.br/reference/442
      # @raise [FitBankApi::Errors::BaseApiError] in case of an API error
      # @raise [Net::HTTPError] if the request status was not 2xx
      def call
        # All CPF/CNPJ must be stripped when using this API, no dashes, dots or slashes are
        # accepted.
        #
        payload = {
          Method: "GeneratePaymentOrder",
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          Value: @value,
          Identifier: @request_id,
          PaymentDate: @payment_date,  
          Beneficiary: {
            Name: @receiver_name,
            AccountInfo: {
              TaxNumber: @receiver_document
            }.merge(@receiver_account_info)
          },
          Payer: {
            TaxNumber: @credentials.cnpj
          }.merge(@sender_bank_info.to_h)
        }

        FitBankApi::Utils::HTTP.post!(@payment_order_url, payload, @credentials)
      end

      sig { params(payment_order_id: String).returns(T::Hash[Symbol, T.untyped]) }
      # Make an API call to get the informtion about a single payment order.
      # @param [String] payment_order_id The payment order ID generated by FitBank and returned
      #   as a response to the GeneratePaymentOrder (DocumentNumber attribute).
      def get_by_id(payment_order_id)
        payload = {
          Method: 'GetPaymentOrder',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          PaymentOrderId: payment_order_id
        }

        FitBankApi::Utils::HTTP.post!(@get_payment_order_url, payload, @credentials)
      end
    end
  end
end
