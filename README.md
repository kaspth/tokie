# Tokie
[![Build Status](https://travis-ci.org/kaspth/tokie.svg)](https://travis-ci.org/kaspth/tokie)

```ruby
# Create a generator to sign, verify, encrypt and decrypt tokens
generator = Tokie::TokenGenerator.new(secret: @secret)

encrypted_token = generator.encrypt("I'm the muffin", expires_in: 1.month) # => Base64 encoded token
signed_token = generator.sign(encrypted_token) # => Base64 encoded token

verified_token = generator.verify(signed_token)
generator.decrypt(verified_token) # => "I'm the muffin"
```
