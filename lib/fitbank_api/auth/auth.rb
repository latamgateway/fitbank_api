# frozen_string_literal: true
# typed:  strict

require 'base64'
require 'net/http'

module FitBankApi
  # Mixin containing functionality for authentication in the FitBak API
  module Authenticatable
    extend T::Sig

    AUTH_ENDPOINT = T.let('main/execute', String)
    private_constant :AUTH_ENDPOINT

    # Authenicate in the FitBank API
    # @param [String] key The username inside FitBank API
    # @param [String] secret The password for FitBak API
    # @return [String] The authentication token which can be used to make requests to FitBank API
    # @raise [AuthenticationError] If it failed to authenticate due to wrong credentials, API malfunction, etc...
    sig { params(key: String, secret: String).returns(String) }
    def authenticate(key, secret)
      uri = URI.join(BASE_URL, AUTH_ENDPOINT)
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(key, secret)
      response = Net::HTTP.start(uri.hostname, uri.port) { |https| https.request(request) }
      puts response.body
      'token'
    end
  end
end
