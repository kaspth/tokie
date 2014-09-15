require 'tokie/claims'
require 'tokie/signer'

module Tokie
  attr_accessor :serializer
  @serializer = Marshal

  class << self
    def encode(*args)
      args.map { |a| Base64.strict_encode64 a }
    end

    def decode(*args)
      args.map { |a| Base64.strict_decode64 a }
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

    class << self
      def verify(signed_token, options = {})
        Signer.verify(signed_token, options)
      end
    end
  end
end
