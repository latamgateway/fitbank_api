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
    let(:payer_name) { 'MATEUS RODRIGUES BARROSO DOS SANTOS' }
    let(:payer_tax_number) { '07890396309' }
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

    describe 'simulate payment' do
      let(:sender_bank_info) do
        FitBankApi::Entities::BankInfo.new(
          bank_code: '450',
          bank_agency: '0001',
          bank_account: '199392157',
          bank_account_digit: '3'
        )
      end

      let(:qr_code_value) { BigDecimal('0.01') }

      let(:qr_code) do
        VCR.use_cassette('pix/qr_code/dynamic/simulate_payment/generate') do
          qr_code_manager.generate(
            value: qr_code_value,
            expiartion_date: Date.today + 30,
            id: SecureRandom.uuid
          )
        end
      end

      let(:qr_code_info) do
        VCR.use_cassette('pix/qr_code/dynamic/simulate_payment/find_by_id') do
          qr_code_manager.find_by_id(
            qr_code[:DocumentNumber].to_s
          )
        end
      end

      let(:hash_code_info) do
        VCR.use_cassette('pix/qr_code/dynamic/simulate_payment/hash_code_info') do
          qr_code_manager.get_info_from_hash(qr_code_info[:GetPixQRCodeByIdInfo][:HashCode])
        end
      end

      let(:pix_key_manager) { FitBankApi::Pix::Key.new(base_url: base_url, credentials: credentials) }

      let(:receiver_pix_key_info) do
        VCR.use_cassette('pix/qr_code/dynamic/simulate_payment/receiver_pix_key_info') do
          pix_key_manager.get_info(
            pix_key: credentials.cnpj,
            key_type: FitBankApi::Pix::Key::KeyType::TaxNumber,
            tax_number: credentials.cnpj
          )
        end
      end

      let(:payment_simulation) do
        VCR.use_cassette('pix/qr_code/dynamic/simulate_payment/simulate_payment') do
          qr_code_manager.simulate_payment(
            sender_bank_info: sender_bank_info,
            receiver_pix_key_info: receiver_pix_key_info,
            request_id: SecureRandom.uuid,
            value: qr_code_value,
            search_protocol: hash_code_info[:SearchProtocol],
            sender_tax_number: payer_tax_number
          )
        end
      end

      let(:qr_code_info_paid) do
        VCR.use_cassette('pix/qr_code/dynamic/simulate_payment/find_by_id_paid') do
          qr_code_manager.find_by_id(
            qr_code[:DocumentNumber].to_s
          )
        end
      end

      it 'simulates payment of dynamic qr code' do
        expect(qr_code[:Success]).to eq('true')
        expect(qr_code_info[:Success]).to eq('true')
        expect(qr_code_info[:GetPixQRCodeByIdInfo][:Status].strip).to eq('Processed')
        expect(qr_code_info[:GetPixQRCodeByIdInfo][:HashCode].strip).not_to be_empty
        expect(hash_code_info[:Success]).to eq('true')
        expect(payment_simulation[:Success]).to eq('true')
        expect(qr_code_info_paid[:Success]).to eq('true')
        expect(qr_code_info_paid[:GetPixQRCodeByIdInfo][:Status]).to eq('Settled')
      end
    end
  end
end
