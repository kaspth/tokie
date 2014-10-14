require 'test_helper'

class TokieClassLevelSecretTest < ActiveSupport::TestCase
  setup do
    @token = Tokie::Token.new('payload')
  end

  test "sign" do
    assert @token.sign
  end

  test "verify" do
    Tokie::Token.verify(@token.sign).tap do |verified|
      assert verified
      assert_respond_to verified, :payload
    end
  end

  test "encrypt" do
    assert @token.encrypt
  end

  test "decrypt" do
    Tokie::Token.decrypt(@token.encrypt).tap do |decrypted|
      assert decrypted
      assert_respond_to decrypted, :payload
    end
  end
end
