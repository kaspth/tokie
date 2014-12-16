require 'tokie/abstract_base'
require 'tokie/encryptor/auth_tag'

module Tokie
  class Encryptor < AbstractBase
    def initialize(claims, **options)
      @cipher = options.delete(:cipher) || 'aes-256-cbc'
      super
    end

    def encrypt
      cipher = build_cipher(:encrypt)
      iv = cipher.random_iv

      encrypted_data = cipher.update(encoded_claims) + cipher.final

      header = ::Base64.strict_encode64(encoded_header)
      auth_tag = generate_digest AuthTag.generate(header, iv, encrypted_data)

      header << '.' << Tokie.encode(@secret, iv, encrypted_data, auth_tag).join('.')
    end

    def decrypt
      if claims = parse_claims
        @serializer.load decrypt_data(claims)
      end
    rescue OpenSSL::Cipher::CipherError, TypeError, ArgumentError
      nil
    end

    def decrypt!
      decrypt || raise(InvalidMessage)
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
        key, @_iv, claims, auth_tag = Tokie.decode(*parts)

        if key == @secret && auth_tag.present? && untampered?(auth_tag, header, @_iv, claims)
          claims
        end
      end

      def decrypt_data(data)
        cipher = build_cipher(:decrypt)
        cipher.iv = @_iv
        cipher.update(data) + cipher.final
      end

      def build_cipher(type)
        OpenSSL::Cipher::Cipher.new(@cipher).tap do |cipher|
          cipher.send type
          cipher.key = @secret
        end
      end

      def untampered?(auth_tag, *data)
        super(auth_tag, AuthTag.new(data).generate)
      end
  end
end
