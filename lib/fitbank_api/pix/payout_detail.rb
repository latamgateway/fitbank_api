# typed: strict
# frozen_string_literal: true

require 'net/http'

module FitBankApi
  module Pix
    # Class wrapping the functionality to get the information about a payout
    # Documentation:
    # * GetPixOutById: https://dev.fitbank.com.br/reference/340, https://dev.fitbank.com.br/docs/3-payments
    # * GetPixOutByDate: https://dev.fitbank.com.br/reference/338, https://dev.fitbank.com.br/docs/3-payments
    class PayoutDetail
      extend T::Sig

      # GetPixOutByDate endpoint requires the number of items per page. We're making it a constant for
      # simplicity. We can remove the constant and make it a param in future if needed.
      GET_BY_DATE_PAGE_SIZE = T.let(500, Integer)
      private_constant :GET_BY_DATE_PAGE_SIZE

      sig do
        params(
          base_url: String,
          credentials: FitBankApi::Entities::Credentials,
          bank_info: FitBankApi::Entities::BankInfo
        ).void
      end
      # Create a class which can query payout status
      # @param [String] base_url Base url to the FtiBank API.
      # @param [FitBankApi::Entities::Credentials] credentials Latam credentials for FitBank
      # @param [FitBankApi::Entities::BankInfo] bank_info The bank information for the one who
      #   created the payout.
      def initialize(base_url:, credentials:, bank_info:)
        @credentials = credentials
        @get_by_id_url = T.let(URI.join(base_url, 'main/execute/GetPixOutById'), URI::Generic)
        @get_date_url = T.let(URI.join(base_url, 'main/execute/GetPixOutById'), URI::Generic)
        @bank_info = bank_info
      end

      sig { params(fitbank_payout_id: String).returns(FitBankApi::Entities::PayoutDetail) }
      # Make an API call to get the information about a single PIX payout.
      # @param [String] fitbank_payout_id The payout ID generated by FitBank and returned
      #   as a response to the GeneratePixOut.
      def get_by_request_id(fitbank_payout_id)
        payload = {
          Method: 'GetPixOutById',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          TaxNumber: @credentials.cnpj,
          DocumentNumber: fitbank_payout_id
        }.merge(@bank_info)

        response = FitBankApi::Utils::HTTP.post!(@get_by_id_url, payload, @credentials)

        FitBankApi::Entities::PayoutDetail.from_response(response[:Infos])
      end

      sig do
        params(
          start_date: Date,
          end_date: Date,
          page_index: Integer
        ).returns(T::Array[FitBankApi::Entities::PayoutDetail])
      end
      # Make an API call to find all payouts in the passed time interval (inclusive)
      # @param [DateTime] start_date Find payouts created from this date
      # @param [DateTime] end_date Find payout created before this date
      # @param [Integer] page_index The API returns the data in pages and each page must be requested via
      #   separate API call.
      # @note The API is not working at the moment (07/10/2022). The bug is reported to FitBank.
      # @todo Make it so that one call to this returns all data and remove the page_index param.
      # @return [Array[FitBankApi::Entities::PayoutDetail]] The list of all payouts between start_date and end_date
      def get_by_date(start_date, end_date, page_index)
        payload = {
          Method: 'GetPixOutById',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          TaxNumber: @credentials.cnpj,
          StartDate: start_date.strftime('%Y/%m/%d'),
          EndDate: end_date.strftime('%Y/%m/%d'),
          PageIndex: page_index,
          PageSize: GET_BY_DATE_PAGE_SIZE
        }.merge(@bank_info)

        FitBankApi::Utils::HTTP.post!(@get_by_date, payload, @credentials)

        # The API is not working at the moment. The response format in the docs was wrong for
        # GetById endpoint so I believe it'll be wrong for this as well. We need to wait for the
        # API to get fixed.
        []
      end
    end
  end
end
