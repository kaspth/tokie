require 'base64'
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

  autoload :Token, 'tokie/token'
end
