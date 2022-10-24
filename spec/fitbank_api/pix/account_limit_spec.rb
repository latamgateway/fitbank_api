# typed: false
# frozen_string_literal: true

RSpec.describe FitBankApi::Pix::AccountLimit do
  let!(:bank_info) { build(:bank_info) }
  let!(:credentials) { build(:credentials) }

  describe 'set limit' do
    xit 'sets daily limit' do
      # TODO: Mock this.
      # Currently (04/10/2022) the API is broken in sandbox. It always returns
      # an error stating that the business_unit_id does not match with the CNPJ.
      # A bug was reported at FitBank.
      limit = described_class.new(
        credentials: credentials,
        bank_info: bank_info,
        base_url: ENV.fetch('FITBANK_BASE_URL')
      )

      limit.update_daily_amount_limit(50_000_000)
    end
  end

  describe 'get limit' do
    xit 'gets daily limit' do
      # TODO: Mock this
      # Currently (04/10/2022) the API is broken in sandbox. It always returns
      # an error stating that the business_unit_id does not match with the CNPJ.
      # A bug was reported at FitBank.
      limit = described_class.new(
        credentials: credentials,
        bank_info: bank_info,
        base_url: ENV.fetch('FITBANK_BASE_URL')
      )

      max_daily_limit = limit.daily_amount_limit
    end
  end
end
