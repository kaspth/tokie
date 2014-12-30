require 'time'
require 'tokie/errors'

module Tokie
  class Claims
    attr_reader :payload, :purpose, :expires_at

    def initialize(payload, options = {})
      @payload = payload
      @purpose = self.class.pick_purpose(options)
      @expires_at = pick_expiration(options)
    end

    class << self
      attr_accessor :expires_in

      def parse(claims, options = {})
        if verify!(claims, options)
          new claims['pld'], expires_at: claims['exp'], for: claims['for']
        end
      end

      def verify!(claims, options)
        raise InvalidSignature if claims['for'] != pick_purpose(options)

        claims['pld'] if parse_expiration(claims['exp'])
      end

      def pick_purpose(options)
        options.fetch(:for) { 'universal' }
      end

      private
        def parse_expiration(expiration)
          return true unless expiration

          Time.iso8601(expiration).tap do |timestamp|
            raise ExpiredClaims if Time.now.utc > timestamp
          end
        end
    end

    def to_h
      { 'pld' => @payload, 'for' => @purpose.to_s }.tap do |claims|
        claims['exp'] = @expires_at.utc.iso8601(3) if @expires_at
      end
    end

    def ==(other)
      other.is_a?(self.class) && @purpose == other.purpose && @payload == other.payload
    end

    private
      def pick_expiration(options)
        return options[:expires_at] if options.key?(:expires_at)

        if expires_in = options.fetch(:expires_in) { self.class.expires_in }
          expires_in.from_now
        end
      end
  end
end
