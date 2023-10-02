# typed: false
# frozen_string_literal: true

require "securerandom"
require "webmock/rspec"

RSpec.describe FitBankApi::Pix::Refund do
  let(:sender_bank_info) { build(:bank_info) }
  let(:credentials) { build(:credentials) }
  let(:base_url) { ENV.fetch("FITBANK_BASE_URL") }

  let(:service) do
    described_class.new(
      base_url: base_url,
      sender_bank_info: sender_bank_info,
      credentials: credentials
    )
  end

  describe "refund" do
    let(:receiver_document) { "03713592000187" }
    let(:receiver_name) { "Carlos Eduardo Furquim Bezerra" }

    let(:receiver_bank_info) do
      build(
        :bank_info,
        bank_code: "450",
        bank_agency: "0001",
        bank_account: "182198382",
        bank_account_digit: "5"
      )
    end

    it "performs refund" do
      # Response taken from FitBank API reference - https://dev.fitbank.com.br/reference/240
      stub_request(
        :post,
        URI.join(base_url, "main/execute/GenerateRefundPixIn")
      ).to_return(
        body: {
          Success: "true",
          Message: "ISI0001 - Método executado com sucesso",
          Url: "http://www.pdfurl.com.br/pdf?filename=2022-03-29/0uws2git.pdf",
          DocumentNumber: 854_127,
          AlreadyExists: "False"
        }.to_json
      )

      response =
        service.call(
          request_id: SecureRandom.uuid,
          pix_payin_id: SecureRandom.random_number(10_000_000),
          receiver_bank_info: receiver_bank_info,
          receiver_name: receiver_name,
          receiver_document: receiver_document,
          value: BigDecimal(SecureRandom.random_number(100))
        )

      expect(response[:Success]).to eq("true")
      expect(response).to have_key(:DocumentNumber)
    end
  end

  describe "refund status" do
    # Refund was created manually for testing. Unable to create refund in sanbox through API gem.
    let(:refund_id) { "269" }

    it "gets status" do
      VCR.use_cassette("pix/refund/status") do
        response = service.find_by_id(refund_id)

        expect(response[:Success]).to eq("true")
        expect(response.fetch(:RefundPixIn)).to have_key(:Status)
      end
    end
  end
end
