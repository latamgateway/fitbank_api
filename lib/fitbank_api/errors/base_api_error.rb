# typed: strict
# frozen_string_literal: true

module FitBankApi
  module Errors
    # A general error raised when the API has Success: "false"
    class BaseApiError < StandardError
      extend T::Sig

      sig { params(body: T::Hash[String, T.untyped]).void }
      # Wrap an error returned by FitBank API. All API calls to the bank respond with
      # 200 OK. The way to check if there is an error is to check the 'Success' field of
      # the body. The body has a 'Message' field describing the general reason for the failure.
      # Usually it also has 'Validation' field which is an array of hashes. Each element has is
      # of this form {'Key': '<name_of_parameter_in_the_api>', 'Value': [<array of errors>]}.
      # @note When the Message is "Houve um erro no sistema. Tente novamente mais tarde" the Validation field
      # is missing from the body of the response. There might be other case in which some of the fields are
      # missing that's why we need to be careful.
      # @param [Hash] The body of the response from FitBank
      def initialize(body)
        super(body.fetch('Message', 'Unknown FitBank error'))
        @validation_errors = T.let(body.fetch('Validation', []), T::Array[T::Hash[String, T::Array[String]]])
      end
    end
  end
end
