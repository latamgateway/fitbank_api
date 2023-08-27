# typed: strict
# frozen_string_literal: true

module FitBankApi
  module Pix
    # Wrapper for PixKey related queries (e.g. register, get info, etc..)
    class Key
      extend T::Sig

      class KeyType < T::Enum
        extend T::Sig

        enums do
          SocialSecurity = new
          # This is CPF/CNPJ
          TaxNumber = new
          Email = new
          PhoneNumber = new
          RandomKeyCode = new
        end

        sig { returns(Integer) }
        def to_i
          case self
          when SocialSecurity then 0
          when TaxNumber then 1
          when Email then 2
          when PhoneNumber then 3
          when RandomKeyCode then 4
          else
            T.absurd(self)
          end
        end
      end

      sig { params(base_url: String, credentials: FitBankApi::Entities::Credentials).void }
      # @param [String] base_url The base URL of the API, defining whether prod
      #   or sandbox environemt is used
      def initialize(base_url:, credentials:)
        @base_url = base_url
        @credentials = credentials
        @get_key_info_url = T.let(URI.join(base_url, '/main/execute/GetInfosPixKey'), URI::Generic)
      end

      sig do
        params(
          pix_key: String,
          key_type: FitBankApi::Pix::Key::KeyType,
          tax_number: String
        ).returns(FitBankApi::Entities::PixKeyInfo)
      end
      def get_info(pix_key:, key_type:, tax_number:)
        payload = {
          Method: 'GetInfosPixKey',
          PartnerId: @credentials.partner_id,
          BusinessUnitId: @credentials.business_unit_id,
          PixKey: pix_key,
          PixKeyType: key_type.to_i,
          TaxNumber: FitBankApi::Utils::TaxNumber.new(tax_number).to_s
        }

        body = FitBankApi::Utils::HTTP.post!(@get_key_info_url, payload, @credentials)

        FitBankApi::Entities::PixKeyInfo.from_hash(body)
      end
    end
  end
end
