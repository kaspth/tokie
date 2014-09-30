require 'tokie/concerns/digestable'
require 'tokie/concerns/secure_comparable'
require 'tokie/errors'

module Tokie
  class Encryptor
    include Digestable, SecureComparable

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
      auth_tag = generate_auth_tag header, iv, encrypted_data

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

      def generate_auth_tag(header, iv, data)
        auth_length = [header.length * 8].pack("Q>")
        generate_digest [header, iv, data, auth_length].join
      end

      def decrypt_claims
        parts = @claims.split('.')
        header = parts.shift
        key, iv, encrypted_data, auth_tag = Tokie.decode *parts

        unless secure_compare auth_tag, generate_auth_tag(header, iv, encrypted_data)
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
