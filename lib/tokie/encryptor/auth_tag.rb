class AuthTag < Struct.new(:parts)
  def self.generate(*parts)
    new(parts).generate
  end

  def generate
    parts.push(auth_length).join
  end

  private
    def header
      parts.first
    end

    def auth_length
      [header.size * 8].pack("Q>")
    end
end
