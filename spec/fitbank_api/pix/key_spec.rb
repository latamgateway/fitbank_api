# typed: false
# frozen_string_literal: true

RSpec.describe FitBankApi::Pix::Key do
  describe 'Pix key info' do
    let(:base_url) { ENV.fetch('FITBANK_BASE_URL') }
    let(:credentials) { build(:credentials) }
    let(:tax_number) { '17774076050' }
    let(:pix_key) { tax_number }
    let(:client) do
      described_class.new(
        base_url: base_url,
        credentials: credentials
      )
    end
    let(:info_response) do
      VCR.use_cassette('pix/key/get_info') do
        client.get_info(
          pix_key: pix_key,
          key_type: described_class::KeyType::TaxNumber,
          tax_number: tax_number
        )
      end
    end

    context 'valid input' do
      it 'gets info' do
        expect(info_response[:Success]).to eq('true')
        expect(info_response).to have_key(:SearchProtocol)
        expect(info_response).to have_key(:Infos)
        expect(info_response[:Infos][:ReceiverTaxNumber]).to eq(tax_number)
        expect(info_response[:Infos][:PixKeyValue]).to eq(pix_key)
      end
    end

    context 'invalid tax_number' do
      let(:tax_number) { '1777407605' }

      it 'raises exception' do
        expect { info_response }.to raise_error(RuntimeError, 'Invalid tax number')
      end
    end
  end
end
