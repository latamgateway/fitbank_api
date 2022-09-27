# typed: false
# frozen_string_literal: true

RSpec.describe FitBankApi::Pix::Payout do
  describe 'payout' do
    let!(:receiver_bank_info) { build(:bank_info) }
    let!(:sender_bank_info) { build(:bank_info) }
    let!(:credentials) { build(:credentials) }
    it 'performs payout' do
      payout = FitBankApi::Pix::Payout.new(
        request_id: '123',
        receiver_bank_info:,
        sender_bank_info:,
        credentials:,
        receiver_name: 'John Doe',
        receiver_document: '240.223.700-76',
        value: 50
      )
      response = payout.call
      expect(response['Success']).to eq('true')
    end
  end
end
