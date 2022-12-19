# typed: false

require 'securerandom'

RSpec.describe FitBankApi::Pix::PaymentOrder do
  describe 'payment order' do
    let!(:sender_bank_info) { build(:bank_info) }

    let!(:receiver_pix_key) { 'test_pix_key' }
    let!(:receiver_bank_info) do
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

    let!(:credentials) { build(:credentials) }

    it 'creates payment order with PIX key' do
      VCR.use_cassette('pix/payment_order/pix_key') do
        payout = described_class.new(
          base_url: ENV.fetch('FITBANK_BASE_URL'),
          request_id: SecureRandom.uuid,
          sender_bank_info: sender_bank_info,
          credentials: credentials,
          receiver_name: 'John Doe',
          # This tax number is taken from FitBank example. It seems
          # like other tax numbers are not working in sandbox
          receiver_document: '17774076050',
          value: BigDecimal('50'),
          payment_date: Time.now.strftime('%Y/%m/%d'),
          receiver_pix_key: receiver_pix_key
        )

        response = payout.call

        expect(response[:Success]).to eq('true')
        expect(response).to have_key(:DocumentNumber)
      end
    end

    it 'creates payment order with bank info' do
      VCR.use_cassette('pix/payment_order/bank_info') do
        payment_order = described_class.new(
          base_url: ENV.fetch('FITBANK_BASE_URL'),
          request_id: SecureRandom.uuid,
          sender_bank_info: sender_bank_info,
          credentials: credentials,
          receiver_name: 'John Doe',
          # This tax number is taken from FitBank example. It seems
          # like other tax numbers are not working in sandbox
          receiver_document: '17774076050',
          value: BigDecimal('50'),
          payment_date: Time.now.strftime('%Y/%m/%d'),
          receiver_bank_info: receiver_bank_info
        )

        response = payment_order.call

        expect(response[:Success]).to eq('true')
        expect(response).to have_key(:DocumentNumber)
      end
    end

    it 'gets info for created payment order' do
      payment_order = described_class.new(
        base_url: ENV.fetch('FITBANK_BASE_URL'),
        request_id: SecureRandom.uuid,
        sender_bank_info: sender_bank_info,
        credentials: credentials,
        receiver_name: 'John Doe',
        receiver_document: '17774076050',
        value: BigDecimal('50'),
        payment_date: Time.now.strftime('%Y/%m/%d'),
        receiver_bank_info: receiver_bank_info
      )

      VCR.use_cassette('pix/payment_order/bank_info') do
        @document_number = payment_order.call[:DocumentNumber].to_s
      end

      VCR.use_cassette('pix/payment_order/get_by_id') do
        response = payment_order.get_by_id(@document_number)
        expect(response).to have_key(:PaymentOrderId)
      end
    end
  end
end
