require 'active_support/core_ext/object/blank'
require 'tokie/abstract_base'

module Tokie
  class Signer < AbstractBase
    def sign
      data = Tokie.encode(encoded_header, encoded_claims).join('.')
      "#{data}.#{generate_digest(data)}"
    end

    def verify
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
