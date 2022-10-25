# typed: strict
# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'
require 'date'
require 'uri'
require 'json'
require 'net/http'

module FitBankApi
  module Pix
    # Used to generate and mutate dynamic QR Code.
    # This QR code is used to create a payment
    # Documentation:
    # * https://dev.fitbank.com.br/docs/4-receipts-and-collection
    # * https://dev.fitbank.com.br/reference/256
    class DynamicQrCode
      extend T::Sig

      # Agent modality of the withdraw transaction, i.e.: withdraw enabler agent,
      # commercial establishment agent or other type of legal entity or correspondent
      # in the country. By default use 2, unless it refers to a Pix Withdraw transaction
      DEFAULT_AGENT_MODALITY = T.let(2, Integer)
      private_constant :DEFAULT_AGENT_MODALITY

      class TransactionPurpose < T::Enum
        extend T::Sig

        enums do
          # This is the default. Acording to FitBank we should use this
          PurchaseOrTransfer = new
          PurchaseWithChange = new
          Withdraw = new
        end

        sig { returns(Integer) }
        def to_i
          case self
          when PurchaseOrTransfer then 0
          when PurchaseWithChange then 1
          when Withdraw then 2
          else
            T.absurd(self)
          end
        end
      end

      # Controlls whether the value of the transaction can be changed dynamically
      # after the QR code is created
      class ChangeType < T::Enum
        extend T::Sig

        enums do
          # Cannot change the value after the QR is created
          None = new
          # Can change the value after the QR code is created
          Allow = new
        end

        sig { returns(Integer) }
        def to_i
          case self
          when None then 0
          when Allow then 1
          else
            T.absurd(self)
          end
        end
      end

      sig do
        params(
          base_url: String,
          receiver_bank_info: FitBankApi::Entities::BankInfo,
          credentials: FitBankApi::Entities::Credentials,
          receiver_pix_key: String,
          receiver_zip_code: String
        ).void
      end
      # @param [String] base_url The base URL of the API, defining whether prod
      #   or sandbox environemt is used
      # @param [FitBankApi::Entities::BankInfo] receiver_bank_info Bank information
      #   for the one receiving the money. In our case this is Latam's bank info
      # @param [FitBankApi::Entities::Credentials] credentials Credentials used to
      #   access the API
      # @param [String] pix_key The PIX key of the one receiving the money.
      # @note The pix_key must be registerd into FitBank's database via:
      #   https://dev.fitbank.com.br/reference/217
      # @param [String] receiver_zip_code Zip Code of the city where the receiver is situtated.
      #   It is allowed to have a dash in the zip code.
      def initialize(
        base_url:,
        receiver_bank_info:,
        credentials:,
        receiver_pix_key:,
        receiver_zip_code:
      )
        @generate_code_url = T.let(
          URI.join(base_url, 'main/execute/GenerateDynamicPixQRCode'), URI::Generic
        )
        @receiver_bank_info = receiver_bank_info
        @credentials = credentials
        @receiver_pix_key = receiver_pix_key
        @receiver_zip_code = receiver_zip_code
      end

      sig do
        params(
          value: BigDecimal,
          expiartion_date: Date,
          id: String
        ).returns(T::Hash[Symbol, T.untyped])
      end
      # Generate a dynamic QR Code which when scanned will transfer money
      # to the receiver_bank_info.
      # @param [BigDecimal] value The amount of the sum transfered when the QR code is scanned
      # @param [Date] expiartion_date The QR code will not be valid after this date
      # @param [String] id Custom identifier for the QR code. You cannot serch by it, nor
      #   use it for retries. You can, however, see it when you query the API for the QR code info.
      def generate(
        value:,
        expiartion_date:,
        id:
      )
        # Endpoint documentation: https://dev.fitbank.com.br/reference/256
        # Fields which are not required are ommited for now
        # TODO: Check if passing receiver name and cpf will force FitBank to do the name/cpf checked
        payload = {
          Method: 'GenerateDynamicPixQRCode',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          PixKey: @receiver_pix_key,
          TaxNumber: @credentials.cnpj,
          PrincipalValue: value.truncate(2).to_s('F'),
          # Any other date format will raise an error: "Houve um erro no sistema. Tente novamente mais tarde"
          # e.g. internal server error.
          ExpirationDate: expiartion_date.strftime('%Y/%m/%d'),
          Identifier: id,
          Address: {
            # The address and the fields in it are optional accordnig to the docs. There
            # are the following bugs:
            # * If the address is missing this error message is returned:
            #   "O campo CityName não pode ser nulo." e.g. the city name should not be empty
            # * If the zip code is missing the same message appeasr (O campo CityName não pode ser nulo.)
            #   CityName does not matter it can be passed or not and the request will be valid.
            ZipCode: @receiver_zip_code
          },
          # Can the request pointed by the QR code be changed after the code
          # is generated
          ChangeType: ChangeType::None.to_i,
          TransactionPurpose: TransactionPurpose::PurchaseOrTransfer.to_i,
          AgentModality: DEFAULT_AGENT_MODALITY,
          # (TransactionValue, TransactionChangeType) are aplicable only
          # if TransactionPurpose = TransactionPurpose::Withdraw
          TransactionValue: nil,
          TransactionChangeType: nil
        }.merge(@receiver_bank_info.to_h)

        FitBankApi::Utils::HTTP.post!(@generate_code_url, payload, @credentials)
      end
    end
  end
end