require 'test_helper'
require 'minitest/mock'

class ClaimsTest < ActiveSupport::TestCase
  setup do
    @claims = Tokie::Claims.new('payload', for: 'test')
  end

  test 'as hash' do
    exp = { 'pld' => 'payload', 'for' => 'test' }
    assert_equal exp, @claims.to_h
  end
end

class ClaimsPurposeTest < ActiveSupport::TestCase
  setup do
    @login_claims = Tokie::Claims.new('payload', for: 'login')
  end

  test 'default purpose without :for option' do
    assert Tokie::Claims.new('payload').purpose
  end

  test 'parse raises with purpose mismatch' do
    assert_raises Tokie::InvalidClaims do
      Tokie::Claims.parse @login_claims.to_h, for: 'not_this'
    end
  end

  test 'equal only with same purpose' do
    assert_equal @login_claims, Tokie::Claims.new('payload', for: 'login')
    refute_equal @login_claims, Tokie::Claims.new('payload', for: 'health')
    refute_equal @login_claims, Tokie::Claims.new('payload')
  end
end

class ClaimsExpirationTest < ActiveSupport::TestCase
  test 'expires_in defaults to class level expiration' do
    with_expiration_in 1.hour do
      encoded_claims = encode_claims.to_h

      travel 59.minutes
      assert Tokie::Claims.parse(encoded_claims)

      travel 5.minutes
      assert_expired encoded_claims
    end
  end

  test 'passing in expires_in overrides class level expiration' do
    with_expiration_in 1.hour do
      encoded_claims = encode_claims expires_in: 2.hours

      travel 1.hour
      assert Tokie::Claims.parse(encoded_claims)

      travel 1.1.hours
      assert_expired encoded_claims
    end
  end

  test 'passing expires_in less than a second is not expired' do
    encoded_claims = encode_claims expires_in: 1.second

    travel 0.5.second
    assert Tokie::Claims.parse(encoded_claims)

    travel 2.seconds
    assert_expired encoded_claims
  end

  test 'passing expires_in nil turns off expiration checking' do
    with_expiration_in 1.hour do
      encoded_claims = encode_claims expires_in: nil

      travel 1.hour
      assert Tokie::Claims.parse(encoded_claims)

      travel 1.hour
      assert Tokie::Claims.parse(encoded_claims)
    end
  end

  test 'passing expires_at sets expiration date' do
    date = Date.today.end_of_day
    claims = Tokie::Claims.new('payload', expires_at: date)

    assert_equal date, claims.expires_at

    travel 1.day
    assert_expired claims.to_h
  end

  test 'passing nil expires_at turns off expiration checking' do
    with_expiration_in 1.hour do
      encoded_claims = encode_claims expires_at: nil

      travel 4.hours
      assert Tokie::Claims.parse(encoded_claims)
    end
  end

  test 'passing expires_at overrides class level expires_in' do
    with_expiration_in 1.hour do
      date = Date.tomorrow.end_of_day
      claims = Tokie::Claims.new('payload', expires_at: date)

      assert_equal date, claims.expires_at

      travel 2.hours
      assert Tokie::Claims.parse(claims.to_h)
    end
  end

  test 'favor expires_at over expires_in' do
    claims = encode_claims expires_at: Date.tomorrow.end_of_day, expires_in: 1.hour

    travel 1.hour
    assert Tokie::Claims.parse(claims)
  end

  private
    def with_expiration_in(expires_in)
      old_expires, Tokie::Claims.expires_in = Tokie::Claims.expires_in, expires_in
      yield
    ensure
      Tokie::Claims.expires_in = old_expires
    end

    def assert_expired(claims, options = {})
      assert_raises Tokie::ExpiredClaims do
        Tokie::Claims.parse claims, options
      end
    end

    def encode_claims(options = {})
      Tokie::Claims.new('payload', options).to_h
    end
end

class ClaimsVersioningTest < ActiveSupport::TestCase
  test "fetching a version" do
    assert_equal Tokie::Claims::V1, Tokie::Claims.version(:V1)
  end

  test "fetching non existent version" do
    assert_raise ArgumentError do
      Tokie::Claims.version(:UninitializedConstant)
    end
  end

  test "versioning" do
    class Tokie::Claims::V200
      def self.verify!(data, options = {})
        '2.0: Much faster! Very lazy!'
      end
    end

    assert_equal Tokie::Claims::V200, Tokie::Claims.version(:V200)

    Tokie::Claims.stub(:latest_version, :V200) do
      assert_equal '2.0: Much faster! Very lazy!', Tokie::Claims.verify!('something')
    end
  end
end
