require 'test_helper'

begin
  require 'openssl'
  OpenSSL::Digest::SHA1
rescue LoadError, NameError
  $stderr.puts "Skipping Signer test: broken OpenSSL install"
else

class SignerTest < ActiveSupport::TestCase
  setup do
    @data = { some: 'data', now: Time.local(2010) }
    @signer = Tokie::Signer.new(Tokie::Claims.new(@data), secret: SECRET)
  end

  test 'simple round tripping' do
    claims = verify(@signer.sign)
    assert_equal @data, claims.payload
  end

  test 'missing signature raises' do
    refute_verified nil
    refute_verified ''
  end

  test 'tampered data raises' do
    header, payload, digest = @signer.sign.split('.')
    refute_verified "#{header.reverse}.#{payload}.#{digest}"
    refute_verified "#{header}.#{payload.reverse}.#{digest}"
    refute_verified "#{header}.#{payload}.#{digest.reverse}"
    refute_verified 'purejunk'
  end

  test 'alternative serializer' do
    claims = Tokie::Claims.new({ foo: 123, 'bar' => Time.utc(2010) })
    token = Tokie::Signer.new(claims, serializer: JSON, secret: SECRET).sign

    exp = { "foo" => 123, "bar" => "2010-01-01 00:00:00 UTC" }
    assert_equal exp, verify(token, serializer: JSON).payload
  end

  def verify(token, options = {})
    Tokie::Signer.new(token, options.merge(secret: SECRET)).verify
  end

  def refute_verified(token)
    assert_raises(Tokie::InvalidSignature) { verify token }
  end
end

end
