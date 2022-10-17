# typed: false
# frozen_string_literal: true

require 'date'
require 'bigdecimal'

RSpec.describe FitBankApi::Pix::DynamicQrCode do
  describe 'payout' do
    let!(:latam_bank_info) { build(:bank_info) }
    let!(:credentials) { build(:credentials) }
    it 'can generate dynamic QR code' do
      # TODO: Mock this
      qr_code = described_class.new(
        base_url: ENV.fetch('FITBANK_BASE_URL'),
        receiver_bank_info: latam_bank_info,
        receiver_pix_key: credentials.cnpj,
        credentials: credentials
      )
      response = qr_code.generate(
        value: BigDecimal('20'),
        expiartion_date: Date.today + 1,
        id: '1'
      )
      puts response
      expect(response['Success']).to eq('true')
    end
  end
end
