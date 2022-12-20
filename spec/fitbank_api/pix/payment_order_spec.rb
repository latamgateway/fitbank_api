# typed: false

require 'securerandom'

RSpec.describe FitBankApi::Pix::PaymentOrder do
  describe 'payment order' do
    let!(:sender_bank_info) { build(:bank_info) }
    let!(:credentials) { build(:credentials) }
    let!(:pix_request_id) { SecureRandom.uuid }
    let!(:bank_info_request_id) { SecureRandom.uuid }

    # This tax number is taken from FitBank example. It seems
    # like other tax numbers are not working in sandbox
    let!(:receiver_document) { '03713592000187' }

    let(:receiver_pix_key) { receiver_document }
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

    let(:payment_order_api) do 
      described_class.new(
        base_url: ENV.fetch('FITBANK_BASE_URL'),
        request_id: request_id,
        sender_bank_info: sender_bank_info,
        credentials: credentials,
        receiver_name: 'John Doe',
        receiver_document: receiver_document,
        value: BigDecimal('50'),
        payment_date: Date.today,
        receiver_pix_key: receiver_pix_key,
        receiver_bank_info: receiver_bank_info
      )
    end

    context 'PIX key' do
      let(:request_id) { pix_request_id }
      let(:receiver_bank_info) { nil }

      before do
        VCR.use_cassette('pix/payment_order/pix_key_generate') do
          @response = payment_order_api.generate
        end
      end

      it 'creates payment order' do
        expect(@response[:Success]).to eq('true')
        expect(@response).to have_key(:DocumentNumber)
      end

      it 'gets info for created payment order' do
        VCR.use_cassette('pix/payment_order/pix_key_get_by_id') do
          expect(payment_order_api.get_by_id(@response.fetch(:DocumentNumber).to_s)).to have_key(:PaymentOrderId)
        end
      end
    end

    context 'Bank Info' do
      let(:request_id) { bank_info_request_id }
      let(:receiver_pix_key) { nil }

      before do
        VCR.use_cassette('pix/payment_order/bank_info_generate') do
          @response = payment_order_api.generate
        end
      end

      it 'creates payment order' do
        expect(@response[:Success]).to eq('true')
        expect(@response).to have_key(:DocumentNumber)
      end

      it 'gets info for created payment order' do
        VCR.use_cassette('pix/payment_order/bank_info_get_by_id') do
          expect(payment_order_api.get_by_id(@response.fetch(:DocumentNumber).to_s)).to have_key(:PaymentOrderId)
        end
      end
    end
  end
end
