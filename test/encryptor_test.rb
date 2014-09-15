require 'test_helper'

begin
  require 'openssl'
  OpenSSL::Digest::SHA1
rescue LoadError, NameError
  $stderr.puts "Skipping Encryptor test: broken OpenSSL install"
else

class EncryptorTest < ActiveSupport::TestCase
  setup do
    @data = { some: 'data', now: Time.local(2010) }
    @encryptor = Tokie::Encryptor.new(Tokie::Claims.new(@data), secret: SECRET)
  end

  test "encrypting twice yields differing cipher text" do
    first_message = @encryptor.encrypt.split('.').first
    second_message = @encryptor.encrypt.split('.').first
    refute_equal first_message, second_message
  end

  test "messing with either encrypted values causes failure" do
    text, iv = @verifier.verify(@encryptor.encrypt).split('.')
    refute_decrypted([iv, text] * '.')
    refute_decrypted([text, munge(iv)] * '.')
    refute_decrypted([munge(text), iv] * '.')
    refute_decrypted([munge(text), munge(iv)] * '.')
  end

  test "messing with verified values causes failures" do
    text, iv = @encryptor.encrypt.split('.')
    refute_verified([iv, text] * '.')
    refute_verified([text, munge(iv)] * '.')
    refute_verified([munge(text), iv] * '.')
    refute_verified([munge(text), munge(iv)] * '.')
  end

  test "signed round tripping" do
    token = @encryptor.encrypt
    assert_equal @data, Tokie::Encryptor.decrypt(token)
  end

  test "alternative serialization method" do
    claims = Tokie::Claims.new({ foo: 123, 'bar' => Time.utc(2010) })
    token = Tokie::Encryptor.new(claims, serializer: JSON, secret: SECRET).encrypt

    exp = { "foo" => 123, "bar" => "2010-01-01 00:00:00 UTC" }
    assert_equal exp, decrypt(token).payload
  end

  test "message obeys strict encoding" do
    bad_encoding_characters = "\n!@#"
    claims = Tokie::Claims.new("This is a very \n\nhumble string"+bad_encoding_characters)
    message, iv = Tokie::Encryptor.new(claims, secret: SECRET).encrypt

    refute_decrypted("#{::Base64.encode64 message.to_s}.#{::Base64.encode64 iv.to_s}")
    refute_verified("#{::Base64.encode64 message.to_s}.#{::Base64.encode64 iv.to_s}")

    refute_decrypted([iv,  message] * bad_encoding_characters)
    refute_verified([iv,  message] * bad_encoding_characters)
  end

  private
    def refute_decrypted(value)
      assert_raise(Tokie::InvalidMessage) do
        claims = Tokie::Claims.new(value)
        decrypt Tokie::Signer.new(claims, secret: SECRET).sign
      end
    end

    def refute_verified(token)
      assert_raise(Tokie::InvalidSignature) { decrypt token }
    end

    def munge(base64_string)
      bits = ::Base64.strict_decode64(base64_string)
      bits.reverse!
      ::Base64.strict_encode64(bits)
    end

    def decrypt(token, options = {})
      Tokie::Encryptor.verify token, options.merge(secret: SECRET)
    end
end

end
