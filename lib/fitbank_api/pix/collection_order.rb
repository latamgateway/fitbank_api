# typed: strict

require 'cpf_cnpj'
require 'date'
require 'uri'
require 'logger'

module FitBankApi
  module Pix
    # Wrapper for FitBank API used for creating a Collection Order
    class CollectionOrder
      extend T::Sig

      TYPE = {
        pix_static_qr_code: 0,
        boleto: 1,
        pix_and_boleto: 2,
        pix_dynamic_qr_code: 3
      }.freeze

      sig do
        params(
          base_url: String,
          receiver_name: String,
          receiver_pix_key: String,
          receiver_pix_key_type: FitBankApi::Pix::Key::KeyType,
          credentials: FitBankApi::Entities::Credentials,
          payer: FitBankApi::Entities::CollectionOrderPayer,
          beneficiary_bank_info: FitBankApi::Entities::BankInfo,
          logger: T.untyped
        ).void
      end
      # Create a collection order API client.
      # @param [String] base_url The base URL of the API, defining whether prod
      #   or sandbox environemt is used.
      # @param [String] receiver_name The name of the one receiving the money.
      # @param [String] receiver_pix_key The PIX key of the one receiving the money.
      # @param [FitBankApi::Pix::Key::KeyType] receiver_pix_key_type The Pix key type.
      #   See FitBankApi::Pix::Key::KeyType for more info.
      # @param [FitBankApi::Entities::Credentials] credentials Latam/company credentials for FitBank.
      # @param [FitBankApi::Entities::CollectionOrderPayer] payer Required information about the payer.
      # @param [FitBankApi::Entities::BankInfk] beneficiery_bank_info Bank information of the one who
      #   will gather the money.
      # @param logger
      def initialize(
        base_url:,
        receiver_name:,
        receiver_pix_key:,
        receiver_pix_key_type:,
        credentials:,
        payer:,
        beneficiary_bank_info:,
        logger: Logger.new($stdout)
      )

        @receiver_name = receiver_name
        @receiver_pix_key = receiver_pix_key
        @receiver_pix_key_type = receiver_pix_key_type
        @credentials = credentials
        @payer = payer
        @beneficiary_bank_info = beneficiary_bank_info

        @collection_order_url = T.let(
          URI.join(base_url, 'main/execute/GenerateCollectionOrder'), URI::Generic
        )
        @get_collection_order_url = T.let(
          URI.join(base_url, 'main/execute/GetCollectionOrder'), URI::Generic
        )
        @cancel_collection_order_url = T.let(
          URI.join(base_url, 'main/execute/CancelCollectionOrder'), URI::Generic
        )
        @logger = logger
      end

      sig do
        params(
          id: String,
          value: BigDecimal,
          expiration_date: Date
        ).returns(T::Hash[Symbol, T.untyped])
      end

      # Create a Collection Order. For FitBank API documentation check:
      # https://dev.fitbank.com.br/docs/2-sending-a-collection-order-in-brazil 
      #   and https://dev.fitbank.com.br/reference/post_generatecollectionorder
      # @param [String] id Idempotency key for the request
      # @param [BigDecimal] value Amount of money to be transferred
      # @param [Date] expiration_date Date on which the Collection Order expires.
      #   Due date is set to one day before this.
      # @raise [FitBankApi::Errors::BaseApiError] in case of an API error
      # @raise [Net::HTTPError] if the request status was not 2xx
      def generate(
        id:,
        value:,
        expiration_date:
      )

        due_date_string = (expiration_date - 1).strftime('%Y-%m-%d')
        expiration_date_string = expiration_date.strftime('%Y-%m-%d')
        fine_date_string = (expiration_date + 1).strftime('%Y-%m-%d')

        payload = {
          Method: 'GenerateCollectionOrder',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          Identifier: id,
          CollectionOrderType: TYPE[:pix_dynamic_qr_code],
          PrincipalValue: Float(value),
          # Interest and Fine always gonna be 0
          InterestPercent: 0,
          FinePercent: 0,
          DueDate: due_date_string,
          ExpirationDate: expiration_date_string,
          FineDate: fine_date_string,
          Payer: @payer.to_h,
          Customer: {
            Name: @receiver_name,
            CustomerAccountInfo: {
              PixKey: @receiver_pix_key,
              PixKeyType: @receiver_pix_key_type.to_i,
              TaxNumber: @credentials.cnpj,
              Bank: @beneficiary_bank_info.bank_code,
              BankBranch: @beneficiary_bank_info.bank_agency,
              BankAccount: @beneficiary_bank_info.bank_account,
              BankAccountDigit: @beneficiary_bank_info.bank_account_digit
            }
          }
        }

        FitBankApi::Utils::HTTP.post!(
          @collection_order_url,
          payload,
          @credentials,
          logger: @logger
        )
      end

      sig { params(document_number: String).returns(T::Hash[Symbol, T.untyped]) }
      # Make an API call to get the informtion about a single collection order.
      # @param [String] document_number The collection order ID generated by FitBank and returned
      #   as a response to the GenerateCollectionOrder (DocumentNumber attribute).
      def get_by_id(document_number)
        payload = {
          Method: 'GetCollectionOrder',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          DocumentNumber: document_number
        }

        # The endpoint for querying CollectionOrders always returns a list, even when passing a specific
        #  DocumentNumber (which is unique), this is why we get the first element of the returned CollectionOrderList.
        FitBankApi::Utils::HTTP.post!(
          @get_collection_order_url,
          payload,
          @credentials,
          logger: @logger
        ).fetch(:CollectionOrderList).first
      end

      sig { params(document_number: String).returns(T::Hash[Symbol, T.untyped]) }
      # Cancel the CollectionOrder by document number
      # @param [String] document_number The collection order ID generated by FitBank and returned
      #   as a response to the GenerateCollectionOrder (DocumentNumber attribute).
      def cancel_by_id(document_number)
        payload = {
          Method: 'CancelCollectionOrder',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          DocumentNumber: document_number
        }

        FitBankApi::Utils::HTTP.post!(
          @cancel_collection_order_url,
          payload,
          @credentials,
          logger: @logger
        )
      end
    end
  end
end
