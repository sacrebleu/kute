module Ui
  module Util
    class Space
      def self.memorize(s)
        if s.downcase.end_with?('m')
          demili(s)
        elsif s.downcase.end_with?('ki')
          binarytohuman(s)
        else
          s
        end
      end

      def self.demili(s)
        sd = s.downcase
        (sd.scan(/\d+/).first || 0).to_i / 1024 if sd.end_with?('m')
      end

      def self.binarytohuman(s)
        sd = s.downcase
        (sd.scan(/\d+/).first || 0).to_i * 1024 if sd.end_with?('ki')
      end

      def self.humanize(val)
        suffixes = %w[b kb Mb Gb Tb Pb Eb]
        idx = 0

        v = val
        while v > 1023
          idx += 1
          v /= 1024
        end

        format('%s%s', v, suffixes[idx])
      end
    end
  end
end
