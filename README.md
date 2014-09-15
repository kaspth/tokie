# Tokie

```ruby
token = Token.new "I'm the muffin", expires_in: 1.month
encrypted_token = token.encrypt(cipher: @cipher) # => Base64 encoded string
signed_token = Token.new(encrypted_token).sign(secret: @secret) # => Base64 encoded string

encrypted_token = Token.verify(signed_token, secret: @secret)
token = Token.decrypt(encrypted_token, cipher: @cipher)['pld']
token.payload # => "I'm the muffin"
```
