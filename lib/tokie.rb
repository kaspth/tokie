require 'tokie/claims'
require 'tokie/signer'
require 'tokie/encryptor'

module Tokie
  attr_accessor :serializer
  module_function :serializer, :serializer=
  @serializer = Marshal

  attr_accessor :secret
  module_function :secret, :secret=

  class << self
    def encode(*args)
      args.map { |a| Base64.strict_encode64 a }
    end

    def decode(*args)
      args.map { |a| Base64.strict_decode64 a }
    end
  end

  class Token
    def initialize(payload, options = {})
      @claims = Claims.new(payload, options)
    end

    def payload
      @claims.payload
    end

    def sign(options = {})
      Signer.new(@claims, options).sign
    end

    def encrypt(options = {})
      Encryptor.new(@claims, options).encrypt
    end

    class << self
      def verify(signed_token, options = {})
        Signer.new(signed_token, options).verify
      end

      def decrypt(encrypted_token, options = {})
        Encryptor.new(encrypted_token, options).decrypt
      end
    end
  end
end
