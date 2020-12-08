module Ui
  module Util
    class Space

      def self.demili(s)
        sd = s.downcase
        if sd.end_with?('m')
          (sd.scan(/\d+/).first || 0).to_i / 1024
        end
      end

      def self.binarytohuman(s)
        sd = s.downcase
        if sd.end_with?('ki')
          (sd.scan(/\d+/).first || 0).to_i * 1024
        end
      end

      def self.humanize(val)
        suffixes = %w|b kb Mb Gb Tb Pb Eb|
        idx = 0

        v = val
        while v > 1023
          idx +=1
          v = v / 1024
        end

        "%s%s" % [v, suffixes[idx]]
      end
    end
  end
end
