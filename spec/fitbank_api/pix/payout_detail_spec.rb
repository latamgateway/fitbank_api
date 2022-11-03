# typed: false
# frozen_string_literal: true

require 'securerandom'

RSpec.describe FitBankApi::Pix::PayoutDetail do
  describe 'payout' do
    let(:payout) { build(:manual_payout) }

    it 'returns payout detail' do
      response = VCR.use_cassette('pix/payout_detail/manual_payout') do
        payout.call
      end

      expect(response[:Success]).to eq('true')

      payout_id = response[:DocumentNumber].to_s

      VCR.use_cassette('pix/payout_detail/get_by_id') do
        payout_detail = described_class.new(
          base_url: ENV['FITBANK_BASE_URL'],
          credentials: build(:credentials),
          bank_info: build(:bank_info)
        ).get_by_request_id(payout_id)

        expect(payout_detail.receiver_bank_info).to eq(payout.receiver_bank_info)
        expect(payout_detail.sender_bank_info).to eq(payout.sender_bank_info)
        expect(payout_detail.status).to eq(FitBankApi::Entities::PayoutDetail::Status::Created)
        expect(payout_detail.fitbank_payout_id).to eq(payout_id)
        expect(payout_detail.end_to_end_id).not_to be_blank
        expect(payout_detail.receipt_url).not_to be_blank
        expect(payout_detail.receiver_document).to eq(payout.receiver_document)
        expect(payout_detail.receiver_name).to eq(payout.receiver_name)
        expect(payout_detail.total_value).to eq(payout.value)
      end
    end
  end
end
