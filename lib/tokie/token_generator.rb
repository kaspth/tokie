module Tokie
  class InvalidSignature < StandardError; end
  class InvalidMessage < StandardError; end

  class TokenGenerator
    def initialize(version: Claims.latest_version, **options)
      @version = version
      @generator_options = options
    end

    def signed_token?(token)
      Signer.new(token, @generator_options).valid?
    end

    def sign(message, options = {})
      claims = Claims.new(message, options)

      Signer.new(claims, @generator_options).sign
    end

    def verify(data, options = {})
      if claims = Signer.new(data, @generator_options).verify
        Claims.version(@version).verify!(claims, options)
      end
    end

    def verify!(data, options = {})
      verify(data, options) || raise(InvalidSignature)
    end

    def encrypted_token?(token)
      Encryptor.new(token, @generator_options).valid?
    end

    def encrypt(message, options = {})
      claims = Claims.new(message, options)

      Encryptor.new(claims, @generator_options).encrypt
    end

    def decrypt(data, options = {})
      if claims = Encryptor.new(data, @generator_options).decrypt
        Claims.version(@version).verify!(claims, options)
      end
    end

    def decrypt!(data, options = {})
      decrypt(data, options) || raise(InvalidMessage)
    end
  end
end
