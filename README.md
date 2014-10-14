# Tokie
[![Build Status](https://travis-ci.org/kaspth/tokie.svg)](https://travis-ci.org/kaspth/tokie)

```ruby
# Set class level secret option so you don't have to pass it in everytime
Tokie::Token.secret = @secret

token = Tokie::Token.new("I'm the muffin", expires_in: 1.month)
encrypted_token = token.encrypt # => Base64 encoded string
signed_token = Tokie::Token.new(encrypted_token).sign # => Base64 encoded string

verified_token = Tokie::Token.new(signed_token).verify
decrypted_token = Tokie::Token.new(verified_token).decrypt
decrypted_token.payload # => "I'm the muffin"
```
