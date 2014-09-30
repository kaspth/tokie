# Tokie

```ruby
# Set class level secret option so you don't have to pass it in everytime
Tokie::Token.secret = @secret

token = Token.new("I'm the muffin", expires_in: 1.month)
encrypted_token = token.encrypt # => Base64 encoded string
signed_token = Token.new(encrypted_token).sign # => Base64 encoded string

encrypted_token = Token.verify(signed_token)
token = Token.decrypt(encrypted_token)
token.payload # => "I'm the muffin"
```
