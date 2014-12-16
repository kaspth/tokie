require 'tokie/abstract_base'

module Tokie
  class Signer < AbstractBase
    def sign
      data = Tokie.encode(encoded_header, encoded_claims).join('.')
      "#{data}.#{generate_digest(data)}"
    end

    def verify
      if claims = parse_claims
        @serializer.load ::Base64.strict_decode64(claims)
      end
    rescue ArgumentError => error
      raise unless error.message =~ %r{invalid base64}
    end

    def verify!
      verify || raise(InvalidSignature)
    end

    private
      def parse_claims
        return if @claims.blank?

        parts = @claims.split('.')
        if parts.all?(&:present?) && untampered?(parts.pop, parts.join('.'))
          parts.last
        end
      end

      def untampered?(digest, data)
        secure_compare digest, generate_digest(data)
      end
  end
end
