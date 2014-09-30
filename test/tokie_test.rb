require 'test_helper'

Tokie::Token.secret = SECRET

class TokieClassLevelSecretTest < ActiveSupport::TestCase
  setup do
    @token = Tokie::Token.new('payload')
  end

  test "sign" do
    assert @token.sign
  end

  test "verify" do
    assert Tokie::Token.verify(@token.sign)
  end

  test "encrypt" do
    assert @token.encrypt
  end

  test "decrypt" do
    assert Tokie::Token.decrypt(@token.encrypt)
  end
end
