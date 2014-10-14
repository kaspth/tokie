require 'tokie/concerns/digestable'
require 'tokie/concerns/secure_comparable'
require 'tokie/errors'

module Tokie
  class AbstractBase
    include Digestable, SecureComparable

    def initialize(claims, secret: Tokie.secret, digest: 'SHA1', serializer: Tokie.serializer)
      @claims = claims
      @secret = secret
      @digest = digest
      @serializer = serializer
    end

    private
      def header
        { 'typ' => 'JWT', 'alg' => @digest.to_s }
      end

      def encoded_header
        @serializer.dump header
      end

      def encoded_claims
        @serializer.dump @claims.to_h
      end
  end
end
