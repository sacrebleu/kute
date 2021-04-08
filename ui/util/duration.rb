module Ui
  module Util
    class Duration
      def self.human(secs, significant_only = true)
        n = secs.round
        parts = [60, 60, 24, 0].map {|d| next n if d.zero?; n, r = n.divmod d; r}
                               .reverse.zip(%w[d h m s]).drop_while {|n, _u| n.zero? }
        if significant_only
          parts = parts[0..1] # no rounding, sorry
          parts << '0' if parts.empty?
        end
        res = parts.flatten.join.split('d').first
        res.match(/[sm]/) ? res : "#{res}d"
      end
    end
  end
end
