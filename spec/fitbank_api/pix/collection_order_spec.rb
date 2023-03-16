# typed: false

require 'securerandom'
require 'date'

RSpec.describe FitBankApi::Pix::CollectionOrder do
  describe 'collection order' do
    let(:receiver_name)         { 'Latam'                                  }
    let(:credentials)           { build(:credentials)                      }
    let(:receiver_pix_key)      { credentials.cnpj                         }
    let(:receiver_pix_key_type) { FitBankApi::Pix::Key::KeyType::TaxNumber }
    let(:payer)                 { build(:collection_order_payer)           }

    let(:collection_order_api) do
      described_class.new(
        base_url: ENV.fetch('FITBANK_BASE_URL'),
        receiver_name: receiver_name,
        receiver_pix_key: receiver_pix_key,
        receiver_pix_key_type: receiver_pix_key_type,
        credentials: credentials,
        payer: payer
      )
    end

    let(:value)           { BigDecimal(10)    }
    let(:id)              { SecureRandom.uuid }
    let(:expiration_date) { Date.today + 1    }

    before do
      VCR.use_cassette('pix/collection_order/generate') do
        @response = collection_order_api.generate(
          id: id,
          value: value,
          expiration_date: expiration_date
        )
      end
    end

    it 'creates collection order' do
      expect(@response[:Success]).to eq('true')
      expect(@response).to have_key(:DocumentNumber)
    end

    it 'gets info for created collection order' do
      VCR.use_cassette('pix/collection_order/get_by_id') do
        expect(collection_order_api.get_by_id(@response.fetch(:DocumentNumber).to_s)).to have_key(:DocumentNumber)
      end
    end

    # FitBank API not working, test ignored until it does
    xit 'cancels created collection order' do
      VCR.use_cassette('pix/collection_order/cancel_by_id') do
        cancel_response = collection_order_api.cancel_by_id(@response.fetch(:DocumentNumber).to_s)
        expect(cancel_response.fetch(:Success)).to eq('true')
      end
    end
  end
end
