module FitBankApi
  module Pix
    # Wrapper for FitBank API used for performing PixIn refund and getting refund details
    # Docs - https://dev.fitbank.com.br/reference/240 - GenerateRefundPixIn; https://dev.fitbank.com.br/reference/335 - GetRefundPixInById
    class Refund
      extend T::Sig

      sig do
        params(
          base_url: String,
          request_id: String,
          pix_payin_id: Integer,
          receiver_bank_info: FitBankApi::Entities::BankInfo,
          sender_bank_info: FitBankApi::Entities::BankInfo,
          credentials: FitBankApi::Entities::Credentials,
          receiver_name: String,
          receiver_document: String,
          value: BigDecimal
        ).void
      end
      # Request a refund for a PIX PayIn
      # @param [String] base_url The base URL of the API, defining whether prod
      #   or sandbox environemt is used
      # @param [String] request_id Idempotency key generated by us
      # @param [String] pix_payin_id ID of the PIX PayIn Receit in the FitBank system (DocumentNumber in PayIn webhook)
      # @param [FitBankApi::Entities::BankInfo] receiver_bank_info The bank info for the
      #   customer receiving for the money
      # @param [FitBankApi::Entities::BankInfo] sender_bank_info The bank info for the
      #   company refunding the money
      # @param [FitBankApi::Entities::Credentials] credentials Company credentials for FitBank
      # @param [String] receiver_name The name of the customer receiving the money
      # @param [String] receiver_document CPF/CNPJ of the customer receiving the money
      # @param [BigDecimal] value The amount of money which will be refunded
      def initialize(
        base_url:,
        request_id:,
        pix_payin_id:,
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
        @pix_payin_id = pix_payin_id
        @receiver_name = receiver_name
        @value = value
        @refund_url = T.let(
          URI.join(base_url, 'main/execute/GenerateRefundPixIn'), URI::Generic
        )
        @get_refund_by_id_url = T.let(
          URI.join(base_url, 'main/execute/GetRefundPixInById'), URI::Generic
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
      def call
        # All CPF/CNPJ must be stripped when using this API, no dashes, dots or slashes are
        # accepted.
        #
        payload = {
          Method: 'GenerateRefundPixIn',
          # PartnerId and BusinessUnitId are constants generated by FitBank, unique for Latam
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          # Receiver Bank Data
          ToTaxNumber: @receiver_document,
          ToName: @receiver_name,
          ToBank: @receiver_bank_info.bank_code,
          ToBankBranch: @receiver_bank_info.bank_agency,
          ToBankAccount: @receiver_bank_info.bank_account,
          ToBankAccountDigit: @receiver_bank_info.bank_account_digit,
          RefundValue: @value,
          #Optional
          CustomerMessage: "",
          # Idempotency key generated by us.
          Identifier: @request_id,
          # ID of the pix payin in the FitBank system
          DocumentNumber: @pix_payin_id,
          # Optional
          Tags: [],
          #Sender Document
          TaxNumber: @credentials.cnpj
        }.merge(@sender_bank_info.to_h)

        FitBankApi::Utils::HTTP.post!(@refund_url, payload, @credentials)
      end

      sig { params(id: String).returns(T::Hash[Symbol, T.untyped]) }
      # @param [String] id The DocumentNumber returned by the API when the refund was requested
      def find_by_id(id)
        payload = {
          Method: "GetRefundPixInById",
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          DocumentNumber: id,
          TaxNumber: @credentials.cnpj
        }.merge(@sender_bank_info.to_h)

        FitBankApi::Utils::HTTP.post!(@get_refund_by_id_url, payload, @credentials)
      end
    end
  end
end
