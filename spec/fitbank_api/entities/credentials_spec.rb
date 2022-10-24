# typed: false
# frozen_string_literal: true

require 'cpf_cnpj'

RSpec.describe FitBankApi::Entities::Credentials do
  describe 'Object' do
    let!(:cnpj) { '16.052.257/0001-27' }
    let!(:username) { 'dummy' }
    let!(:password) { 'dummy' }
    let!(:mkt_place_id) { 1 }
    let!(:business_unit_id) { 1 }
    let!(:partner_id) { 1 }

    context 'attributes' do
      it 'has attr_accessors' do
        credentials = described_class.new(
          cnpj: cnpj,
          username: username,
          password: password,
          mkt_place_id: mkt_place_id,
          business_unit_id: business_unit_id,
          partner_id: partner_id
        )

        expect(credentials).to respond_to(:cnpj)
        expect(credentials).to respond_to(:username)
        expect(credentials).to respond_to(:password)
        expect(credentials).to respond_to(:mkt_place_id)
        expect(credentials).to respond_to(:business_unit_id)
        expect(credentials).to respond_to(:partner_id)

        expect(credentials).to respond_to(:cnpj=)
        expect(credentials).to respond_to(:username=)
        expect(credentials).to respond_to(:password=)
        expect(credentials).to respond_to(:mkt_place_id=)
        expect(credentials).to respond_to(:business_unit_id=)
        expect(credentials).to respond_to(:partner_id=)
      end
    end

    context 'initialization' do
      it 'is initialized with correct values' do
        credentials = described_class.new(
          cnpj: cnpj,
          username: username,
          password: password,
          mkt_place_id: mkt_place_id,
          business_unit_id: business_unit_id,
          partner_id: partner_id
        )

        expect(credentials.cnpj).to eq(CNPJ.new(cnpj).stripped)
        expect(credentials.username).to eq(username)
        expect(credentials.password).to eq(password)
        expect(credentials.mkt_place_id).to eq(mkt_place_id)
        expect(credentials.business_unit_id).to eq(business_unit_id)
        expect(credentials.partner_id).to eq(partner_id)
      end
    end
  end
end
