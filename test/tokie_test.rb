require 'test_helper'

class TokieClassLevelSecretTest < ActiveSupport::TestCase
  setup do
    @token = Tokie::Token.new('payload')
  end

  test "sign" do
    assert_equal 3, @token.sign.split('.').size
  end

  test "verify" do
    Tokie::Token.verify(@token.sign).tap do |verified|
      assert verified
      assert_respond_to verified, :payload
    end
  end

  test "verify with purpose" do
    token = Tokie::Token.new('payload', for: 'login').sign

    assert_equal 'payload', Tokie::Token.verify(token, for: 'login').payload
  end

  test "encrypt" do
    assert_equal 5, @token.encrypt.split('.').size
  end

  test "decrypt" do
    Tokie::Token.decrypt(@token.encrypt).tap do |decrypted|
      assert decrypted
      assert_respond_to decrypted, :payload
    end
  end
end
