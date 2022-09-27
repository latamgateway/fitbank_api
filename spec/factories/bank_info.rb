# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :bank_info, class: FitBankApi::Entities::BankInfo do
    bank_code { '450' }
    bank_agency { '0001' }
    bank_account { '3134806' }
    bank_account_digit { '1' }

    initialize_with do
      new(bank_code:, bank_agency:, bank_account:, bank_account_digit:)
    end
  end
end
