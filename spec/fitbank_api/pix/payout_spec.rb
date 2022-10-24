# typed: false
# frozen_string_literal: true

require 'securerandom'

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

    it 'performs payout' do
      VCR.use_cassette('pix/payout/manual') do
        payout = FitBankApi::Pix::Payout.new(
          request_id: SecureRandom.uuid,
          receiver_bank_info: receiver_bank_info,
          sender_bank_info: sender_bank_info,
          credentials: credentials,
          receiver_name: 'John Doe',
          # This tax number is taken from FitBank example. It seems
          # like other tax numbers are not working in sandbox
          receiver_document: '17774076050',
          value: 50
        )

        response = payout.call

        expect(response[:Success]).to eq('true')
        expect(response).to have_key(:DocumentNumber)
      end
    end
  end
end
