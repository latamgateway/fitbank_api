# typed: false
# frozen_string_literal: true

RSpec.describe FitBankApi::Entities::BankInfo do
  describe 'Object' do
    let!(:bank_code) { '218' }
    let!(:bank_agency) { '0001' }
    let!(:bank_account) { '3134806' }
    let!(:bank_account_digit) { '1' }

    context 'attributes' do
      it 'has attr_accessors' do
        bank_info = described_class.new(bank_code:, bank_agency:, bank_account:)

        expect(bank_info).to respond_to(:bank_code)
        expect(bank_info).to respond_to(:bank_agency)
        expect(bank_info).to respond_to(:bank_account)
        expect(bank_info).to respond_to(:bank_account_digit)

        expect(bank_info).to respond_to(:bank_code=)
        expect(bank_info).to respond_to(:bank_agency=)
        expect(bank_info).to respond_to(:bank_account=)
        expect(bank_info).to respond_to(:bank_account_digit=)
      end
    end

    context 'initialization' do
      it 'is initialized with correct values' do
        bank_info = described_class.new(bank_code:, bank_agency:, bank_account:, bank_account_digit:)

        expect(bank_info.bank_code).to eq(bank_code)
        expect(bank_info.bank_agency).to eq(bank_agency)
        expect(bank_info.bank_account).to eq(bank_account)
        expect(bank_info.bank_account_digit).to eq(bank_account_digit)
      end
    end
  end
end
