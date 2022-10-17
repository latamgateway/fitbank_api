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
    # * https://dev.fitbank.com.br/reference/255
    class DynamicQrCode
      extend T::Sig

      # Agent modality of the withdraw transaction, i.e.: withdraw enabler agent,
      # commercial establishment agent or other type of legal entity or correspondent
      # in the country. By 2, unless it refers to a Pix Withdraw transaction
      DEFAULT_AGENT_MODALITY = T.let(2, Integer)
      private_constant :DEFAULT_AGENT_MODALITY

      class TransactionPurpose < T::Enum
        extend T::Sig

        enums do
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
          receiver_pix_key: String
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
      def initialize(
        base_url:,
        receiver_bank_info:,
        credentials:,
        receiver_pix_key:
      )
        @generate_code_url = T.let(
          URI.join(base_url, 'main/execute/GenerateDynamicPixQRCode'), URI::Generic
        )
        @receiver_bank_info = receiver_bank_info
        @credentials = credentials
        @receiver_pix_key = receiver_pix_key
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
      # @param [String] id (Optional) Custom identifier for the QR code. You cannot serch by it, nor
      #   use it for retries. You can, however, see it when you query the API for the QR code info.
      def generate(
        value:,
        expiartion_date:,
        id: ''
      )
        # Endpoint documentation: https://dev.fitbank.com.br/reference/256
        # Fields which are not required are ommited for now
        # TODO: Check if passing receiver name and cpf will force FitBank to do the name/cpf checked
        payload = {
          Method: 'GenerateDynamicPixQRCode',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          PixKey: @credentials.cnpj,
          TaxNumber: @credentials.cnpj,
          PayerTaxNumber: '65023491021',
          PayerName: 'João da Silva Pereira',
          PrincipalValue: 100,
          ExpirationDate: '31/01/2023',
          Address: {
            AddressLine: 'Rua Niterói',
            AddressLine2: 'string',
            ZipCode: '60731-305',
            Neighborhood: 'Canindezinho',
            CityCode: '451',
            CityName: 'Fortaleza',
            State: 'Ceará',
            AddressType: 1,
            Country: 'Brasil',
            Complement: 'Apto 01',
            Reference: 'Próximo ao mercado'
          },
          ChangeType: ChangeType::None.to_i,
          AdditionalData: [
            {
              Name: 'pagamento',
              Value: '300'
            }
          ],
          PayerRequest: 'pagamento',
          TransactionPurpose: TransactionPurpose::Withdraw.to_i,
          TransactionValue: nil,
          AgentModality: DEFAULT_AGENT_MODALITY,
          TransactionChangeType: nil
        }.merge(@receiver_bank_info.to_h)

        puts payload.to_json

        request = Net::HTTP::Post.new(@generate_code_url)
        request.body = payload.to_json
        request.basic_auth(@credentials.username, @credentials.password)
        request['accept'] = 'application/json'
        request['content-type'] = 'application/json'
        response = Net::HTTP.start(
          @generate_code_url.hostname,
          @generate_code_url.port,
          use_ssl: true
        ) { |http| http.request(request) }

        JSON.parse(response.body)
      end
    end
  end
end
