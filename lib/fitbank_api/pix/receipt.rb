# typed: strict
# frozen_string_literal: true

module FitBankApi
  module Pix
    # Wrapper for FitBank API used for querying PixIn receipts
    # Docs - https://dev.fitbank.com.br/reference/480 - GetPixInById;
    class Receipt
      extend T::Sig

      sig do
        params(
          base_url: String,
          company_bank_info: FitBankApi::Entities::BankInfo,
          credentials: FitBankApi::Entities::Credentials
        ).void
      end
      # @param [String] base_url The base URL of the API, defining whether prod
      #   or sandbox environemt is used
      # @param [FitBankApi::Entities::BankInfo] company_bank_info The bank info for the company.
      #   company refunding the money
      # @param [FitBankApi::Entities::Credentials] credentials Company credentials for FitBank

      def initialize(
        base_url: ,
        company_bank_info: ,
        credentials: 
      )
        @company_bank_info = company_bank_info
        @credentials = credentials

        @get_by_id_url = T.let(
          URI.join(base_url, 'main/execute/GetPixInById'), URI::Generic
        )
      end

      sig { params(e2e_id: String).returns(T::Hash[Symbol, T.untyped]) }
      # https://dev.fitbank.com.br/reference/480
      # @param [String] e2e_id End-To-End ID sent in the webhook on successful payment
      def get_by_e2e_id(e2e_id)
        payload = {
          Method: "GetPixInById",
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          EndToEndId: e2e_id,
          TaxNumber: @credentials.cnpj
        }.merge(@company_bank_info.to_h)

        FitBankApi::Utils::HTTP.post!(@get_by_id_url, payload, @credentials)
      end
    end
  end
end
