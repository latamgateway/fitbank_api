# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :bank_info, class: FitBankApi::Entities::BankInfo do
    bank_code { ENV['LATAM_BANK_CODE'] }
    bank_agency { ENV['LATAM_BANK_AGENCY'] }
    bank_account { ENV['LATAM_BANK_ACCOUNT'] }
    bank_account_digit { ENV['LATAM_BANK_ACCOUNT_DIGIT'] }
    initialize_with do
      new(bank_code:, bank_agency:, bank_account:, bank_account_digit:)
    end
  end
end
