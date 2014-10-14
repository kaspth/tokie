require 'tokie/abstract_base'

module Tokie
  class Encryptor < AbstractBase
    def initialize(claims, **options)
      @cipher = options.delete(:cipher) || 'aes-256-cbc'
      super
    end

    def encrypt
      cipher = build_cipher.encrypt
      iv = cipher.random_iv

      encrypted_data = cipher.update(encoded_claims) + cipher.final

      header = ::Base64.strict_encode64(encoded_header)
      auth_tag = generate_auth_tag header, iv, encrypted_data

      header << '.' << Tokie.encode(@secret, iv, encrypted_data, auth_tag).join('.')
    end

    def decrypt(options = {})
      @claims = Claims.parse(decrypt_claims, options)
    end

    private
      def header
        super.tap do |header|
          header['enc'] = @cipher.to_s
        end
      end

      def build_cipher
        OpenSSL::Cipher::Cipher.new(@cipher).tap do |c|
          c.key = @secret
        end
      end

      def generate_auth_tag(header, iv, data)
        auth_length = [header.length * 8].pack("Q>")
        generate_digest [header, iv, data, auth_length].join
      end

      def decrypt_claims
        parts = @claims.split('.')
        header = parts.shift
        key, iv, encrypted_data, auth_tag = Tokie.decode *parts

        unless auth_tag.present? && secure_compare(auth_tag, generate_auth_tag(header, iv, encrypted_data))
          raise InvalidMessage
        end

        cipher = build_cipher.decrypt
        cipher.iv = iv
        decrypted_data = cipher.update(encrypted_data) + cipher.final

        @serializer.load(decrypted_data)
      rescue OpenSSL::Cipher::CipherError, TypeError, ArgumentError
        raise InvalidMessage
      end
  end
end
