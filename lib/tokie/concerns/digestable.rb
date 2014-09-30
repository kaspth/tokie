require 'active_support/concern'

module Digestable
  extend ActiveSupport::Concern

  private
    def generate_digest(data)
      require 'openssl' unless defined?(OpenSSL)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.const_get(@digest).new, @secret, data)
    end
end
