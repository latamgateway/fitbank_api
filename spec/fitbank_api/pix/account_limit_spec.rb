# typed: false
# frozen_string_literal: true

RSpec.describe FitBankApi::Pix::AccountLimit do
  let!(:bank_info) { build(:bank_info) }
  let!(:credentials) { build(:credentials) }

  describe 'set limit' do
    xit 'sets daily limit' do
      # TODO: Mock this
      limit = described_class.new(credentials:, bank_info:)
      limit.daily_amount_limit = 50_000_000
    end
  end

  describe 'get limit' do
    xit 'gets daily limit' do
      # TODO: Mock this
      limit = described_class.new(credentials:, bank_info:)
      max_daily_limit = limit.daily_amount_limit
    end
  end
end
