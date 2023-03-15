# typed: strict
# frozen_string_literal: true

require 'uri'
require 'logger'

module FitBankApi
  module Utils
    # Utility module wrapping HTTP requests to FitBank
    module HTTP
      extend T::Sig

      sig do
        params(
          uri: URI::Generic,
          payload: T::Hash[Symbol, T.untyped],
          credentials: FitBankApi::Entities::Credentials,
          logger: T.untyped
        ).returns(T::Hash[Symbol, T.untyped])
      end
      # Make a post request with settings setup to use FitBank
      # @param [URI] uri The endpoint
      # @param [Hash] payload The body of the post request
      # @param [FitBankApi::Entities::Credentials] credentials Credentials used for simple auth
      # @param logger Logger class used to print the request. If nil is passed nothing will be logged.
      # @return [Hash] The response body if the request was successful
      # @raise [FitBankApi::Errors::BaseApiError] If the API returns "Success: false" but the HTTP
      #   request was successful
      # @raise [Net::HTTPError] If the HTTP request has failed (status code different than 2xx)
      def self.post!(uri, payload, credentials, logger: Logger.new($stdout))
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true
        http.set_debug_output(logger) if logger

        request = Net::HTTP::Post.new(uri)
        request.body = payload.to_json
        request.basic_auth(credentials.username, credentials.password)
        request['accept'] = 'application/json'
        request['content-type'] = 'application/json'

        response = http.request(request)

        response.value

        body = T.let(JSON.parse(response.body, symbolize_names: true), T::Hash[Symbol, T.untyped])

        raise FitBankApi::Errors::BaseApiError, body if body[:Success] == 'false'

        body
      end
    end
  end
end
