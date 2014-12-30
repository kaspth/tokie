require 'tokie/abstract_base'
require 'tokie/encryptor/auth_tag'
require 'tokie/encryptor/cipher'

module Tokie
  class Encryptor < AbstractBase
    def initialize(claims, **options)
      cipher = options.delete(:cipher) || 'aes-256-cbc'
      super

      @cipher = Cipher.new(cipher, @secret)
    end

    def encrypt
      encrypted_data = @cipher.encrypt(encoded_claims)

      header = ::Base64.strict_encode64(encoded_header)
      auth_tag = generate_digest AuthTag.generate(header, @cipher.iv, encrypted_data)

      header << '.' << Tokie.encode(@secret, @cipher.iv, encrypted_data, auth_tag).join('.')
    end

    def decrypt
      parse
    rescue OpenSSL::Cipher::CipherError, TypeError, ArgumentError
      nil
    end

    private
      def header
        super.tap do |header|
          header['enc'] = @cipher.to_s
        end
      end

      def parse_claims
        parts = @claims.split('.')
        header = parts.shift
        key, @cipher.iv, claims, auth_tag = Tokie.decode(*parts)

        if key == @secret && auth_tag.present? && untampered?(auth_tag, header, @cipher.iv, claims)
          claims
        end
      end

      def before_load(claims)
        @cipher.decrypt(claims)
      end

      def untampered?(auth_tag, *data)
        super(auth_tag, AuthTag.new(data).generate)
      end
  end
end
