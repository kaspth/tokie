class Cipher < Struct.new(:algorithm, :key)
  attr_accessor :iv

  def encrypt(data)
    cipher = build_cipher(:encrypt)
    @iv = cipher.random_iv
    cipher.update(data) + cipher.final
  end

  def decrypt(data)
    cipher = build_cipher(:decrypt)
    cipher.iv = @iv
    cipher.update(data) + cipher.final
  end

  def to_s
    algorithm.to_s
  end

  private
    def build_cipher(type)
      OpenSSL::Cipher::Cipher.new(algorithm).tap do |cipher|
        cipher.send type
        cipher.key = key
      end
    end
end
