module Tokie
  class TokenGenerator
    def initialize(options = {})
      @generator_options = options
    end

    def sign(message, options = {})
      claims = Claims.new(message, options)

      Signer.new(claims, @generator_options).sign
    end

    def verify(data, options = {})
      if claims = Signer.new(data, @generator_options).verify
        Claims.verify!(claims, options)
      end
    end

    def encrypt(message, options = {})
      claims = Claims.new(message, options)

      Encryptor.new(claims, @generator_options).encrypt
    end

    def decrypt(data, options = {})
      if claims = Encryptor.new(data, @generator_options).decrypt
        Claims.verify!(claims, options)
      end
    end
  end
end
