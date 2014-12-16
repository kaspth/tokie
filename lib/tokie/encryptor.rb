require 'tokie/abstract_base'

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
      auth_tag = generate_auth_tag header, iv, encrypted_data

      header << '.' << Tokie.encode(@secret, iv, encrypted_data, auth_tag).join('.')
    end

    def decrypt
      if data = parse_claims
        @serializer.load decrypt_data(data)
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
        key, @_iv, data, auth_tag = Tokie.decode(*parts)

        if key == @secret && auth_tag.present? && untampered?(auth_tag, header, @_iv, data)
          data
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

      def generate_auth_tag(header, iv, data)
        auth_length = [header.length * 8].pack("Q>")
        generate_digest [header, iv, data, auth_length].join
      end

      def untampered?(auth_tag, *data)
        secure_compare(auth_tag, generate_auth_tag(*data))
      end
  end
end
