require 'test_helper'

class TokenGeneratorTest < ActiveSupport::TestCase
  setup do
    @generator = Tokie::TokenGenerator.new(secret: SECRET)
  end

  test "sign" do
    assert_equal 3, @generator.sign('payload').split('.').size
  end

  test "verify" do
    assert_verified 'payload'
    assert_verified({ foo: 'bar' })
  end

  test "verify with purpose" do
    assert_verified 'payload', for: 'login'
  end

  test "encrypt" do
    assert_equal 5, @generator.encrypt('payload').split('.').size
  end

  test "decrypt" do
    @generator.decrypt(@generator.encrypt('payload')).tap do |decrypted|
      assert_equal 'payload', decrypted
    end
  end

  private
    def assert_verified(message, options = {})
      actual = @generator.verify(@generator.sign(message, options), options)
      assert_equal message, actual
    end
end
