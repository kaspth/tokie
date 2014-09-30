require 'active_support/core_ext/object/blank'
require 'tokie/concerns/digestable'
require 'tokie/concerns/secure_comparable'
require 'tokie/errors'

module Tokie
  class Signer
    include Digestable, SecureComparable

    def initialize(claims, secret:, digest: 'SHA1', serializer: Tokie.serializer)
      @claims = claims
      @secret = secret
      @digest = digest
      @serializer = serializer
    end

    def sign
      data = Tokie.encode(encoded_header, encoded_claims).join('.')
      "#{data}.#{generate_digest(data)}"
    end

    class << self
      def verify(signed_token, options = {})
        Claims.parse new(signed_token, options).send(:parse_claims), options
      end
    end

    private
      def encoded_header
        { 'typ' => 'JWT', 'alg' => @digest.to_s }.to_s
      end

      def encoded_claims
        @serializer.dump @claims.to_h
      end

      # Claims can be a signed token which can be parsed
      def parse_claims
        raise InvalidSignature if @claims.blank?

        *token_data, digest = @claims.split('.').tap do |parts|
          raise InvalidSignature unless parts.all?(&:present?)
        end

        unless secure_compare digest, generate_digest(token_data.join('.'))
          raise InvalidSignature
        end

        begin
          @serializer.load ::Base64.strict_decode64(token_data.last)
        rescue ArgumentError => argument_error
          raise InvalidSignature if argument_error.message =~ %r{invalid base64}
          raise
        end
      end
  end
end
