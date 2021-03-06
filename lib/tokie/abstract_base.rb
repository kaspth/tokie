require 'active_support/security_utils'
require 'active_support/core_ext/object/blank'

module Tokie
  class AbstractBase
    def initialize(claims, secret:, digest: 'SHA1', serializer: Marshal)
      @claims = claims
      @secret = secret
      @digest = digest
      @serializer = serializer
    end

    def valid?
      true if parse_claims
    end
    alias :validate :valid?

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

      def parse
        if claims = parse_claims
          @serializer.load before_load(claims)
        end
      end

      def untampered?(digest, data)
        ActiveSupport::SecurityUtils.secure_compare digest, generate_digest(data)
      end

      def generate_digest(data)
        require 'openssl' unless defined?(OpenSSL)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get(@digest).new, @secret, data)
      end
  end
end
