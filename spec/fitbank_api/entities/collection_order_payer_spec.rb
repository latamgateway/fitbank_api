# typed: false
# frozen_string_literal: true

require 'date'

RSpec.describe FitBankApi::Entities::CollectionOrderPayer do
  describe 'Object' do
    let!(:name) { 'Test Payer' }
    let!(:birth_date) { Date.new(2000,1,1) }
    let!(:tax_number) { '16.052.257/0001-27' }
    let!(:email) { 'test@test.com' }
    let!(:mobile) { '88999999999' }
    let!(:occupation) { 'dev' }
    let!(:nationality) { 'Brasileiro' }
    let!(:country) { 'Brasil' }

    let!(:payer) do
      described_class.new(
        name: name,
        birth_date: birth_date,
        tax_number: tax_number,
        email: email,
        mobile: mobile,
        occupation: occupation,
        nationality: nationality,
        country: country
      )
    end

    context 'attributes' do
      it 'has attr_accessors' do
        expect(payer).to respond_to(:name)
        expect(payer).to respond_to(:birth_date)
        expect(payer).to respond_to(:tax_number)
        expect(payer).to respond_to(:email)
        expect(payer).to respond_to(:mobile)
        expect(payer).to respond_to(:occupation)
        expect(payer).to respond_to(:nationality)
        expect(payer).to respond_to(:country)

        expect(payer).to respond_to(:name=)
        expect(payer).to respond_to(:birth_date=)
        expect(payer).to respond_to(:tax_number=)
        expect(payer).to respond_to(:email=)
        expect(payer).to respond_to(:mobile=)
        expect(payer).to respond_to(:occupation=)
        expect(payer).to respond_to(:nationality=)
        expect(payer).to respond_to(:country=)
      end
    end

    context 'initialization' do
      it 'is initialized with correct values' do
        expect(payer.name).to eq(name)
        expect(payer.birth_date).to eq(birth_date)
        expect(payer.tax_number).to eq(FitBankApi::Utils::TaxNumber.new(tax_number).to_s)
        expect(payer.email).to eq(email)
        expect(payer.mobile).to eq(mobile)
        expect(payer.occupation).to eq(occupation)
        expect(payer.nationality).to eq(nationality)
        expect(payer.country).to eq(country)
      end
    end

    context 'to hash' do
      it 'returns the correct hash' do
        expected_hash = {
          Name: payer.name,
          BirthDate: payer.birth_date.strftime('%Y/%m/%d'),
          Occupation: payer.occupation,
          Nationality: payer.nationality,
          Country: payer.country,
          PayerContactInfo: {
            Mail: payer.email,
            Phone: payer.mobile
          },
          PayerAccountInfo: {
            TaxNumber: payer.tax_number
          }
        }

        expect(payer.to_h).to eq(expected_hash)
      end
    end
  end
end
