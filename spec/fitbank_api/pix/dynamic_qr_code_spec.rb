# typed: false
# frozen_string_literal: true

require 'date'
require 'bigdecimal'
require 'securerandom'

RSpec.describe FitBankApi::Pix::DynamicQrCode do
  describe 'Dynamic QR code' do

    let(:latam_bank_info) { build(:bank_info) }
    let(:credentials) { build(:credentials) }
    let(:base_url) { ENV.fetch('FITBANK_BASE_URL') }
    let(:receiver_zip_code) { ENV.fetch('LATAM_ZIP_CODE') }
    let(:payer_name) { 'Amarillys Félix' }
    let(:payer_tax_number) { '17774076050' }
    let(:qr_code_manager) do
      described_class.new(
          base_url: base_url,
          receiver_bank_info: latam_bank_info,
          receiver_pix_key: credentials.cnpj,
          credentials: credentials,
          receiver_zip_code: receiver_zip_code,
          payer_name: payer_name,
          payer_tax_number: payer_tax_number
        )
    end
    let(:generate_response) do
      VCR.use_cassette('pix/qr_code/dynamic/generate') do
        qr_code_manager.generate(
          value: BigDecimal('20'),
          expiartion_date: Date.today + 30,
          id: SecureRandom.uuid
        )
      end
    end

    it 'can generate dynamic QR code' do
      expect(generate_response[:Success]).to eq('true')
      expect(generate_response).to have_key(:DocumentNumber)
    end

    it 'can get dynamic QR code' do
      VCR.use_cassette('pix/qr_code/dynamic/find_by_id') do
        response = qr_code_manager.find_by_id(generate_response[:DocumentNumber].to_s)

        expect(response[:Success]).to eq('true')
        expect(response).to have_key(:GetPixQRCodeByIdInfo)
        expect(response[:GetPixQRCodeByIdInfo]).to have_key(:QRCodeBase64)
        expect(response[:GetPixQRCodeByIdInfo]).to have_key(:HashCode)
        expect(response[:GetPixQRCodeByIdInfo][:Status]).not_to eq('Error')
      end
    end
  end
end
