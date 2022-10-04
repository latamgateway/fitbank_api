# typed: false
# frozen_string_literal: true

RSpec.describe FitBankApi::Pix::Payout do
  describe 'payout' do
    let!(:sender_bank_info) { build(:bank_info) }
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
    xit 'performs payout' do
      # TODO: Mock this
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
