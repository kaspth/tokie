# Tokie
[![Build Status](https://travis-ci.org/kaspth/tokie.svg)](https://travis-ci.org/kaspth/tokie)

```ruby
# Set class level secret option so you don't have to pass it in everytime
Tokie::Token.secret = @secret

token = Tokie::Token.new("I'm the muffin", expires_in: 1.month)
encrypted_token = token.encrypt # => Base64 encoded string
signed_token = Tokie::Token.new(encrypted_token).sign # => Base64 encoded string

encrypted_token = Tokie::Token.verify(signed_token)
token = Tokie::Token.decrypt(encrypted_token)
token.payload # => "I'm the muffin"
```
