# typed: false
# frozen_string_literal: true

require 'securerandom'

RSpec.describe FitBankApi::Pix::Payout do
  let(:sender_bank_info) { build(:bank_info) }
  # This tax number is taken from FitBank example. It seems
  # like other tax numbers are not working in sandbox
  let(:receiver_tax_number) { '03713592000187' }
  let(:receiver_name) { 'Carlos Eduardo Furquim Bezerra' }
  let(:receiver_bank_info) do
    # This data is taken from an example FitBank sent us and it's working.
    # Different kinds of bank_account_digit can fail (even if they are acceptable to the API),
    # the same goes for other props.
    build(
      :bank_info,
      bank_code: '450',
      bank_agency: '0001',
      bank_account: '182198382',
      bank_account_digit: '5'
    )
  end
  let(:credentials) { build(:credentials) }
  let(:value) { BigDecimal('0.01') }
  let(:base_url) { ENV.fetch('FITBANK_BASE_URL') }
  let(:payout) do
    described_class.new(
      base_url: base_url,
      request_id: SecureRandom.uuid,
      receiver_bank_info: receiver_bank_info,
      sender_bank_info: sender_bank_info,
      credentials: credentials,
      receiver_name: receiver_name,
      receiver_document: receiver_tax_number,
      value: value
    )
  end

  describe 'manual payout' do
    it 'performs manual payout' do
      response = VCR.use_cassette('pix/payout/manual') do
        payout.call
      end

      expect(response[:Success]).to eq('true')
      expect(response).to have_key(:DocumentNumber)
    end
  end

  describe 'pix key payout' do
    let(:pix_key) { '03713592000187' }
    let(:pix_key_type) { FitBankApi::Pix::Key::KeyType::TaxNumber }

    let(:key_info) do
      VCR.use_cassette('pix/payout/pix_key/key_info') do
        FitBankApi::Pix::Key.new(
          base_url: base_url,
          credentials: credentials
        ).get_info(
          pix_key: pix_key,
          key_type: pix_key_type,
          tax_number: receiver_tax_number
        )
      end
    end

    it 'performs pix key payout' do
      response = VCR.use_cassette('pix/payout/pix_key/payout') do
        payout.by_pix_key(key_info: key_info)
      end

      expect(response[:Success]).to eq('true')
      expect(response).to have_key(:DocumentNumber)
    end
  end
end
