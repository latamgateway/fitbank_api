# typed: false
# frozen_string_literal: true

require 'securerandom'

FactoryBot.define do
  factory :manual_payout, class: FitBankApi::Pix::Payout do
    sender_bank_info do
      build(
        :bank_info,
        bank_code: ENV['LATAM_BANK_CODE'],
        bank_agency: ENV['LATAM_BANK_AGENCY'],
        bank_account: ENV['LATAM_BANK_ACCOUNT'],
        bank_account_digit: ENV['LATAM_BANK_ACCOUNT_DIGIT']
      )
    end

    receiver_bank_info do
      build(
        :bank_info,
        bank_code: '450',
        bank_agency: '0001',
        bank_account: '182198382',
        bank_account_digit: '5'
      )
    end

    credentials { build(:credentials) }

    initialize_with do
      new(
        sender_bank_info: sender_bank_info,
        receiver_bank_info: receiver_bank_info,
        credentials: credentials,
        receiver_name: 'John Doe',
        receiver_document: '17774076050',
        base_url: ENV.fetch('FITBANK_BASE_URL'),
        request_id: SecureRandom.uuid,
        value: BigDecimal('50')
      )
    end
  end
end
