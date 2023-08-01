# typed: strict
# frozen_string_literal: true

require 'date'

module FitBankApi
  module Entities
    # Wrapper for payer info required in GenerateCollectionOrder
    class CollectionOrderPayer
      extend T::Sig

      sig { returns(String) }
      attr_accessor :name, :tax_number, :email, :mobile, :occupation, :nationality, :country

      sig { returns(Date) }
      attr_accessor :birth_date

      sig do
        params(
          name: String,
          birth_date: Date,
          tax_number: String,
          email: String,
          mobile: String,
          occupation: String,
          nationality: String,
          country: String
        ).void
      end
      # Create credentials representing our user inside FitBank
      # @param [String] name The name of the payer.
      # @param [Date] birth_date The date of birth of the payer.
      # @param [String] tax_number The CPF/CNPJ of the payer.
      #   All CPF/CNPJ must be stripped when using this API, no dashes, dots or slashes are
      #   accepted.
      # @param [String] email The email of the payer.
      # @param [String] mobile The mobile number of the payer.
      # @param [String] occupation Occupation of the payer.
      # @param [String] nationality Nationality of the payer.
      # @param [String] country Country of residence of the payer.
      def initialize(
        name:,
        birth_date:,
        tax_number:,
        email:,
        mobile:,
        occupation: '',
        nationality: '',
        country: ''
      )

        @name = name
        @birth_date = birth_date
        @tax_number = T.let(FitBankApi::Utils::TaxNumber.new(tax_number).to_s, String)
        @email = email
        @mobile = mobile
        @occupation = occupation
        @nationality = nationality
        @country = country
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      # Get a hash representation of the payer. This can be directly
      # merged into the GenerateCollectionOrder API endpoint payloads
      # @return [Hash]
      def to_h
        {
          Name: @name,
          BirthDate: @birth_date.strftime('%Y-%m-%d'),
          Occupation: @occupation,
          Nationality: @nationality,
          Country: @country,
          PayerContactInfo: {
            Mail: @email,
            Phone: @mobile
          },
          PayerAccountInfo: {
            TaxNumber: @tax_number
          }
        }
      end
    end
  end
end
