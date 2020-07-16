require 'base64'
module RbPager
  module Base64Encoder
    def encode(data)
      Base64.strict_encode64(data)
    end

    def decode(data)
      return nil if data.nil?

      decoded_data = Base64.strict_decode64(data)
      Hash[
        decoded_data.split(',').map do |pair|
          k, v = pair.split(':', 2)
        end
      ]
    end
  end
end
