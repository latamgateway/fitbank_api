# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :credentials, class: FitBankApi::Entities::Credentials do
    cnpj { ENV['LATAM_CNPJ'] }
    username { ENV['FITBANK_KEY'] }
    password { ENV['FITBANK_SECRET'] }
    mkt_place_id { ENV['MKT_PLACE_ID'].to_i }
    business_unit_id { ENV['BUSINESS_UNIT_ID'].to_i }
    partner_id { ENV['PARTNER_ID'].to_i }

    initialize_with do
      new(
        cnpj: cnpj,
        username: username,
        password: password,
        mkt_place_id: mkt_place_id,
        business_unit_id: business_unit_id,
        partner_id: partner_id
      )
    end
  end
end
