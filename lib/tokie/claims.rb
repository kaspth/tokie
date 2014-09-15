require 'tokie/errors'

module Tokie
  class Claims
    attr_reader :payload, :purpose, :expires_at

    def initialize(payload, options = {})
      @payload = payload
      @purpose = self.class.pick_purpose(options)
      @expires_at = pick_expiration(options).try { utc.iso8601(3) }
    end

    class << self
      attr_accessor :expires_in

      def parse(claims, options)
        raise ExpiredClaim if expired?(claims['exp'])
        raise InvalidSignature if claims['for'] != pick_purpose(options)

        new claims['pld'], expires_at: claims['exp'], for: claims['for']
      end

      def pick_purpose(options)
        options.fetch(:for) { 'universal' }
      end

      def expired?(timestamp)
        timestamp && Time.now.utc > timestamp
      end
    end

    def to_h
      { 'pld' => @payload, 'for' => @purpose.to_s }.tap do |claims|
        claims['exp'] = @expires_at if @expires_at
      end
    end

    def ==(other)
      super && purpose == other.purpose
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
