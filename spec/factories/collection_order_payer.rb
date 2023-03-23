# typed: false
# frozen_string_literal: true

require 'date'

FactoryBot.define do
  factory :collection_order_payer, class: FitBankApi::Entities::CollectionOrderPayer do
    initialize_with do
      new(
        name: "Test Payer",
        birth_date: Date.new(2000,1,1),
        tax_number: "88899988811",
        email: "test@test.com",
        mobile: "88999999999",
        occupation: "dev",
        nationality: "Brasileiro",
        country: "Brasil"
      )
    end
  end
end
