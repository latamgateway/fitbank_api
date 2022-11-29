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

    describe 'generate' do
      it 'generates dynamic QR code' do
        expect(generate_response[:Success]).to eq('true')
        expect(generate_response).to have_key(:DocumentNumber)
      end
    end

    describe 'info' do
      let(:info_by_id) do
        VCR.use_cassette('pix/qr_code/dynamic/find_by_id') do
          qr_code_manager.find_by_id(generate_response[:DocumentNumber].to_s)
        end
      end

      it 'gets dynamic QR code' do
        expect(info_by_id[:Success]).to eq('true')
        expect(info_by_id).to have_key(:GetPixQRCodeByIdInfo)
        expect(info_by_id[:GetPixQRCodeByIdInfo]).to have_key(:QRCodeBase64)
        expect(info_by_id[:GetPixQRCodeByIdInfo][:QRCodeBase64].strip).not_to be_empty
        expect(info_by_id[:GetPixQRCodeByIdInfo]).to have_key(:HashCode)
        expect(info_by_id[:GetPixQRCodeByIdInfo][:HashCode].strip).not_to be_empty
        expect(info_by_id[:GetPixQRCodeByIdInfo][:Status]).not_to eq('Error')
      end

      it 'get info by hash code' do
        info_by_hash_code = VCR.use_cassette('pix/qr_code/dynamic/info_by_hash_code') do
          qr_code_manager.get_info_from_hash(info_by_id[:GetPixQRCodeByIdInfo][:HashCode])
        end

        expect(info_by_hash_code[:Success]).to eq('true')
        expect(info_by_hash_code).to have_key(:SearchProtocol)
        expect(info_by_hash_code).to have_key(:Infos)
        expect(info_by_hash_code[:Infos]).to have_key(:FinalValue)
      end
    end
  end
end
