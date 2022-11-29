# typed: strict
# frozen_string_literal: true

module FitBankApi
  module Utils
    class TaxNumber
      extend T::Sig

      sig { returns(String) }
      attr_reader :tax_number

      sig { params(tax_number: String).void }
      def initialize(tax_number)
        if CPF.valid?(tax_number)
          @tax_number = T.let(CPF.new(tax_number).stripped, String)
        elsif CNPJ.valid?(tax_number)
          @tax_number = T.let(CNPJ.new(tax_number).stripped, String)
        else
          raise 'Invalid tax number'
        end
      end

      sig { returns(String) }
      def to_s
        @tax_number
      end
    end
  end
end
