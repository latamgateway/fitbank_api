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
      const :isbp, String
      const :name, String
      const :key_type, Integer
      const :pix_key, String
      const :tax_number, String
      const :search_protocol, Integer

      sig { params(body: T::Hash[Symbol, T.untyped]).returns(FitBankApi::Entities::PixKeyInfo) }
      def self.from_hash(body)
        bank_info = FitBankApi::Entities::BankInfo.new(
          bank_code: body[:Infos][:ReceiverBank],
          bank_agency: body[:Infos][:ReceiverBankBranch],
          bank_account: body[:Infos][:ReceiverBankAccount],
          bank_account_digit: body[:Infos][:ReceiverAccountType]
        )

        FitBankApi::Entities::PixKeyInfo.new(
          bank_info: bank_info,
          isbp: body[:Infos][:ReceiverISPB],
          name: body[:Infos][:ReceiverName],
          key_type: Integer(body[:Infos][:PixKeyType]),
          pix_key: body[:Infos][:PixKeyValue],
          tax_number: body[:Infos][:ReceiverTaxNumber],
          search_protocol: Integer(body[:SearchProtocol])
        )
      end
    end
  end
end
