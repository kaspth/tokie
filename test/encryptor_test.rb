require 'test_helper'

class EncryptorTest < ActiveSupport::TestCase
  setup do
    @data = { some: 'data', now: Time.local(2010) }
    @encryptor = Tokie::Encryptor.new(Tokie::Claims.new(@data))
  end

  test "encrypting twice yields differing cipher text" do
    first_message  = @encryptor.encrypt.split('.')[2]
    second_message = @encryptor.encrypt.split('.')[2]
    refute_equal first_message, second_message
  end

  test "messing with either encrypted values causes failure" do
    header, key, claims, iv, auth_tag = @encryptor.encrypt.split('.')
    refute_decrypted [header, key, claims, auth_tag, iv] * '.'

    refute_decrypted [munge(header), key, claims, iv, auth_tag] * '.'
    refute_decrypted [header, munge(key), claims, iv, auth_tag] * '.'
    refute_decrypted [header, key, munge(claims), iv, auth_tag] * '.'
    refute_decrypted [header, key, claims, munge(iv), auth_tag] * '.'
    refute_decrypted [header, key, claims, iv, munge(auth_tag)] * '.'

    refute_decrypted [munge(header), munge(key), munge(claims), munge(iv), munge(auth_tag)] * '.'
  end

  test "signed round tripping" do
    token = @encryptor.encrypt
    assert_equal @data, decrypt(token)['pld']
  end

  test "alternative serialization method" do
    claims = Tokie::Claims.new({ foo: 123, 'bar' => Time.utc(2010) })
    token = Tokie::Encryptor.new(claims, serializer: JSON).encrypt

    exp = { "foo" => 123, "bar" => "2010-01-01 00:00:00 UTC" }
    assert_equal exp, decrypt(token, serializer: JSON)['pld']
  end

  private
    def refute_decrypted(token)
      assert_raise(Tokie::InvalidMessage) { decrypt token }
    end

    def munge(base64_string)
      bits = ::Base64.strict_decode64(base64_string)
      bits.reverse!
      ::Base64.strict_encode64(bits)
    end

    def encode64(args)
      args.map { |a| ::Base64.encode64 a }
    end

    def decrypt(token, options = {})
      Tokie::Encryptor.new(token, options).decrypt!
    end
end
