require 'tokie/errors'

module Tokie
  class Signer
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
        Claims.parse decode_claims(signed_token), options
      end

      private
        def decode_claims(signed_token)
          raise InvalidSignature if signed_token.blank?

          *token_data, digest = signed_token.split('.')
          data = token_data.join('.')

          if token_data.all(&:present?) && digest.present? && secure_compare(digest, generate_digest(data))
            begin
              @serializer.load ::Base64.strict_decode64(token_data.last)
            rescue ArgumentError => argument_error
              raise InvalidSignature if argument_error.message =~ %r{invalid base64}
              raise
            end
          else
            raise InvalidSignature
          end
        end

        # constant-time comparison algorithm to prevent timing attacks
        def secure_compare(a, b)
          return false unless a.bytesize == b.bytesize

          l = a.unpack "C#{a.bytesize}"

          res = 0
          b.each_byte { |byte| res |= byte ^ l.shift }
          res == 0
        end
    end

    private
      def encoded_header
        { 'typ' => 'JWT', 'alg' => @digest.to_s }.to_s
      end

      def encoded_claims
        @serializer.dump @claims.to_h
      end

      def generate_digest(data)
        require 'openssl' unless defined?(OpenSSL)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get(@digest).new, @secret, data)
      end
  end
end
