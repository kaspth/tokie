require 'tokie/abstract_base'

module Tokie
  class Signer < AbstractBase
    def sign
      data = Tokie.encode(encoded_header, encoded_claims).join('.')
      "#{data}.#{generate_digest(data)}"
    end

    def verify
      parse
    rescue ArgumentError => error
      raise unless error.message =~ %r{invalid base64}
    end

    private
      def parse_claims
        return if @claims.blank?

        parts = @claims.split('.')
        if parts.all?(&:present?) && untampered?(parts.pop, parts.join('.'))
          parts.last
        end
      end

      def before_load(claims)
        ::Base64.strict_decode64(claims)
      end
  end
end
