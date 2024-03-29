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
          receiver_zip_code: String,
          payer_name: String,
          payer_tax_number: String
        ).void
      end
      # @param [String] base_url The base URL of the API, defining whether prod
      #   or sandbox environemt is used
      # @param [FitBankApi::Entities::BankInfo] receiver_bank_info Bank information
      #   for the one receiving the money. In our case this is Latam's bank info
      # @param [FitBankApi::Entities::Credentials] credentials Credentials used to
      #   access the API
      # @param [String] receiver_pix_key The PIX key of the one receiving the money.
      # @param [String] receiver_zip_code Zip Code of the city where the receiver is situtated.
      #   It is allowed to have a dash in the zip code.
      # @param [String] payer_name The name of the one sending the money. Acording to FitBank
      #   this is now required from the central bank of Brazil.
      # @param [String] payer_tax_number CPF/CNPJ of the one sending the money. Acording to FitBank
      #   this is now required from the central bank of Brazil.
      # @note For sandbox the pix_key must be registerd into FitBank's database via:
      #   https://dev.fitbank.com.br/reference/217. For production we can use already existing
      #   PIX key.
      def initialize(
        base_url:,
        receiver_bank_info:,
        credentials:,
        receiver_pix_key:,
        receiver_zip_code:,
        payer_name:,
        payer_tax_number:
      )
        @generate_code_url = T.let(
          URI.join(base_url, 'main/execute/GenerateDynamicPixQRCode'), URI::Generic
        )
        @get_code_by_id_url = T.let(
          URI.join(base_url, 'main/execute/GetPixQRCodeById'), URI::Generic
        )
        @get_info_from_hash_url = T.let(
          URI.join(base_url, 'main/execute/GetInfosPixHashCode'), URI::Generic
        )

        @payer_tax_number = T.let(
          FitBankApi::Utils::TaxNumber.new(payer_tax_number).to_s, String
        )
        @base_url = base_url
        @receiver_bank_info = receiver_bank_info
        @credentials = credentials
        @receiver_pix_key = receiver_pix_key
        @receiver_zip_code = receiver_zip_code
        @payer_name = payer_name
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
      # @param [String] id Custom identifier for the QR code. You cannot serch by it, but it
      #   it can be used for retries, since the API will return an error if you use the same code twice.
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
          PrincipalValue: value.to_s('F'),
          # Any other date format will raise an error: "Houve um erro no sistema. Tente novamente mais tarde"
          # i.e. internal server error.
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
          TransactionChangeType: nil,
          PayerName: @payer_name,
          PayerTaxNumber: @payer_tax_number
        }.merge(@receiver_bank_info.to_h)

        FitBankApi::Utils::HTTP.post!(@generate_code_url, payload, @credentials)
      end

      sig { params(id: String).returns(T::Hash[Symbol, T.untyped]) }
      # Retrieve the base64 encoded QRCode image
      # @param [String] id The DocumentNumber returned by the API when the QR code
      #   was generated
      def find_by_id(id)
        payload = {
          Method: 'GetPixQRCodeById',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          DocumentNumber: id,
          TaxNumber: @credentials.cnpj
        }

        FitBankApi::Utils::HTTP.post!(@get_code_by_id_url, payload, @credentials)
      end

      sig { params(hash: String).returns(T::Hash[Symbol, T.untyped]) }
      # Retrieve data for the dynamic qr code by the hash returned from FitBankApi::Pix::DynamicQrCode#find_by_id
      # The response contains more info (including bank details and SearchProtocol used to simulate payment in
      # sandbox environment)
      #
      # Docs: https://dev.fitbank.com.br/reference/274
      # @param [String] hash The HashCode returned from FitBankApi::Pix::DynamicQrCode#find_by_id
      def get_info_from_hash(hash)
        decoded_hash = Base64.decode64(hash)
        payload = {
          Method: 'GetInfosPixHashCode',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          Hash: decoded_hash,
          TaxNumber: @credentials.cnpj
        }

        FitBankApi::Utils::HTTP.post!(@get_info_from_hash_url, payload, @credentials)
      end

      sig do
        params(
          sender_bank_info: FitBankApi::Entities::BankInfo,
          sender_tax_number: String,
          receiver_pix_key_info: FitBankApi::Entities::PixKeyInfo,
          request_id: String,
          value: BigDecimal,
          search_protocol: T.any(Integer, String)
        ).returns(T::Hash[Symbol, T.untyped])
      end
      # Simulate a payment of Dynamic QR Code in sandbox environemt. This will trigger a
      # webhook and will change the status of the dynamic qr code to paid in FitBank's system.
      # The steps to do it are as follows:
      #  1. Gnerate Dynamic QR Code by calling FitBankApi::Pix::DynamicQrCode#generate
      #  2. Take the DocumentNumber returned from FitBankApi::Pix::DynamicQrCode#generate
      #  3. Take the HashCode returned by FitBankApi::Pix::DynamicQrCode#find_by_id
      #  4. Take the SearchProtocol returned by FitBankApi::Pix::DynamicQrCode#get_info_from_hash
      #  5. Make a payout by pix key with FitBankApi::Pix::Payout#by_pix_key. In the payout
      #   the sender is the customer and the receiver is company calling the API
      # @param [FitBankApi::Entities::BankInfo] sender_bank_info Bank info of the customer who
      #   is paying via QRCode
      # @param [String] sender_tax_number The CPF/CNPJ of the person/company paying the PIX via
      #   qr code.
      # @param [FitBankApi::Entities::PixKeyInfo] receiver_pix_key_info Pix key info generated
      #   by FitBankApi::Pix::Key#get_info. This is the PIX key info of the one receiving the
      #   money.
      # @param [Strng] request_id Idempotency key for the request
      # @param [BigDecimal] value The value of the DynamicQrCode
      # @param [Strng, Integer] search_protocol The SearchProtocol field returned by
      #   FitBankApi::Pix::DynamicQrCode#get_info_from_hash
      #
      # @note This function should be used only in sandbox environemt
      def simulate_payment(
        sender_bank_info:,
        sender_tax_number:,
        receiver_pix_key_info:,
        request_id:,
        value:,
        search_protocol:
      )
        payout_manager = FitBankApi::Pix::Payout.new(
          base_url: @base_url,
          request_id: request_id,
          receiver_bank_info: receiver_pix_key_info.bank_info,
          sender_bank_info: sender_bank_info,
          credentials: @credentials,
          receiver_name: receiver_pix_key_info.name,
          receiver_document: receiver_pix_key_info.tax_number,
          value: value
        )

        payout_manager.by_pix_key(
          key_info: receiver_pix_key_info,
          search_protocol: search_protocol,
          sender_tax_number: sender_tax_number,
          pix_key_type: FitBankApi::Pix::Key::KeyType::TaxNumber
        )
      end
    end
  end
end
