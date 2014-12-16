require 'active_support/core_ext/object/blank'
require 'tokie/errors'

module Tokie
  class AbstractBase
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

      def parse
        if claims = parse_claims
          @serializer.load before_load(claims)
        end
      end

      def untampered?(digest, data)
        secure_compare digest, generate_digest(data)
      end

      def generate_digest(data)
        require 'openssl' unless defined?(OpenSSL)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get(@digest).new, @secret, data)
      end

      # FIXME: Ditch in favor of ActiveSupport::SecurityUtils once 4.2 ships.
      # constant-time comparison algorithm to prevent timing attacks
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack "C#{a.bytesize}"

        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
      end
  end
end
