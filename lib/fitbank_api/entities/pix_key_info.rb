# typed: strict
# frozen_string_literal: true

require_relative './bank_info'

module FitBankApi
  module Entities
    extend T::Sig

    # Wraps PixKeyInfo result returned by FitBankApi::Pix::Key#get_info
    class PixKeyInfo < T::Struct
      extend T::Sig

      const :bank_info, FitBankApi::Entities::BankInfo
      # Sometimes the API returns null for this field. It could happen so that
      # in two consequtive calls we get null and non null. There is no pattern
      # to when the API could return null. We don't use this field for anything.
      # We should investigate if it becomes required.
      const :isbp, T.nilable(String)
      const :name, String
      const :key_type, String
      const :pix_key, String
      const :tax_number, String
      const :search_protocol, Integer

      sig { params(body: T::Hash[Symbol, T.untyped]).returns(FitBankApi::Entities::PixKeyInfo) }
      def self.from_hash(body)
        # The API omits leading zeros for the bank_agency/bank_branch field.
        # However the request to perform pix payment will crash if the leading
        # zeroes are missing. The agency has 4 digits in total. So we prepend the
        # missing zeroes.
        bank_agency = body[:Infos][:ReceiverBankBranch]
        to_prepend = 4 - bank_agency.size
        to_prepend.times { bank_agency.prepend('0') }

        bank_info = FitBankApi::Entities::BankInfo.new(
          bank_code: body[:Infos][:ReceiverBank],
          bank_agency: bank_agency,
          bank_account: body[:Infos][:ReceiverBankAccount],
          bank_account_digit: body[:Infos][:ReceiverBankAccountDigit]
        )

        FitBankApi::Entities::PixKeyInfo.new(
          bank_info: bank_info,
          isbp: body[:Infos][:ReceiverISPB],
          name: body[:Infos][:ReceiverName],
          key_type: body[:Infos][:PixKeyType],
          pix_key: body[:Infos][:PixKeyValue],
          tax_number: body[:Infos][:ReceiverTaxNumber],
          search_protocol: body[:SearchProtocol]
        )
      end
    end
  end
end
