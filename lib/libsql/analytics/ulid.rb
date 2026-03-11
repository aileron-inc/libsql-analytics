# frozen_string_literal: true

module Libsql
  module Analytics
    module Ulid
      ENCODING = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'

      def self.generate
        ms = (Time.now.to_f * 1000).to_i
        time_part = encode_time(ms)
        random_part = encode_random
        "#{time_part}#{random_part}"
      end

      def self.encode_time(ms)
        result = ''
        10.times do
          result = ENCODING[ms % 32] + result
          ms /= 32
        end
        result
      end

      def self.encode_random
        result = ''
        16.times { result += ENCODING[SecureRandom.random_number(32)] }
        result
      end
    end
  end
end
