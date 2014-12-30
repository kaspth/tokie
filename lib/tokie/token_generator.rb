module Tokie
  class TokenGenerator
    def initialize(payload_or_token, claim_options = {})
      @payload = extract_payload(payload_or_token)
      @claim_options = claim_options
    end

    def payload
      claims.payload
    end

    def to_s
      @encoded_data
    end

    def sign(options = {})
      @encoded_data = Signer.new(claims, options).sign
    end

    def verify(options = {})
      parse_claims Signer.new(@payload, options).verify
      self
    end

    def encrypt(options = {})
      @encoded_data = Encryptor.new(claims, options).encrypt
    end

    def decrypt(options = {})
      parse_claims Encryptor.new(@payload, options).decrypt
      self
    end

    private
      def extract_payload(token)
        token.respond_to?(:payload) ? token.payload : token
      end

      def parse_claims(data)
        @claims = Claims.parse(data, @claim_options)
      end

      def claims
        @claims ||= Claims.new(@payload, @claim_options)
      end
  end
end
