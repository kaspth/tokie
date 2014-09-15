require 'tokie/errors'

module Tokie
  class Encryptor
    def initialize(claims, secret:, digest: 'SHA1', serializer: nil, cipher: nil)
      @claims = claims
      @secret = secret
      @digest = digest
      @cipher = cipher || 'aes-256-cbc'
      @serializer = serializer || Tokie.serializer
    end

    def encrypt
      cipher = build_cipher.encrypt
      iv = cipher.random_iv

      encrypted_data = cipher.update(encoded_claims) + cipher.final

      header = ::Base64.strict_encode64(encoded_header)
      auth_tag = cipher.auth_tag header.size

      header << '.' << Tokie.encode(@secret, iv, encrypted_data, auth_tag).join('.')
    end

    class << self
      def decrypt(encrypted_token, options = {})
        Claims.parse new(encrypted_token, options).send(:decrypt_claims), options
      end
    end

    private
      def encoded_header
        { 'typ' => 'JWT', 'alg' => @digest.to_s, 'enc' => @cipher.to_s }.to_s
      end

      def encoded_claims
        @serializer.dump @claims.to_h
      end

      def build_cipher
        OpenSSL::Cipher::Cipher.new(@cipher).tap do |c|
          c.key = @secret
        end
      end

      def decrypt_claims
        header, key, iv, encrypted_data, auth_tag = Tokie.decode encrypted_token.split('.')

        cipher = build_cipher.decrypt
        cipher.iv = iv
        decrypted_data = cipher.update(encrypted_data) + cipher.final

        @serializer.load(decrypted_data)
      rescue OpenSSL::Cipher::CipherError, TypeError, ArgumentError
        raise InvalidMessage
      end
  end
end
