require 'test_helper'

class SignerTest < ActiveSupport::TestCase
  setup do
    @data = { some: 'data', now: Time.local(2010) }
    @signer = signer Tokie::Claims.new(@data)
  end

  test 'simple round tripping' do
    claims = verify(@signer.sign)
    assert_equal @data, claims['pld']
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
    token = signer(claims, serializer: JSON).sign

    exp = { "foo" => 123, "bar" => "2010-01-01 00:00:00 UTC" }
    assert_equal exp, verify(token, serializer: JSON)['pld']
  end

  test 'verify without raising' do
    refute signer('purejunk').verify
  end

  test 'valid?' do
    assert signer(@signer.sign).valid?
  end

  def signer(data, options = {})
    Tokie::Signer.new(data, options.merge(secret: SECRET))
  end

  def verify(token, options = {})
    signer(token, options).verify!
  end

  def refute_verified(token)
    assert_raises(Tokie::InvalidSignature) { verify token }
  end
end
