module Ui
  module Layout
    # formatting utility class
    class Column
      attr_accessor :name, :width, :align

      def initialize(*ary)
        @name = ary[0]
        @width = ary[1]
        @align = ary.length > 2 ? ary[2] : :right
      end

      def align_right?
        @align == :right
      end

      # dynamically widen column if there's a wider field than its default width
      def rejigger(w)
        @width = w if w > @width
      end

      # render this column's name according to the layout rules
      def title
        v = name.to_s.capitalize
        align_right? ? Justifier.rjust(v, width) : Justifier.ljust(v, width)
      end

      # render the target according to this column's layout rules
      def render(target)
        align_right? ? Justifier.rjust(target, width) : Justifier.ljust(target, width)
      rescue => e
        raise "Column #{name} failed: #{e.message}"
      end

      def trim(s)
        s[0..width-2]
      end
    end

    # encode justifier logic
    class Justifier
      def self.ljust(source, width)
        if source
          u = $pastel.strip(source).length
          w = width - u
          raise "[#{source}]:#{u} exceeds column width #{width}" if w < 1
        else
          w = width
        end

        empty = ' ' * w
        "#{source}#{empty}"
      end

      def self.rjust(source, width)
        if source
          u = $pastel.strip(source).length
          w = width - u
          raise "[#{source}]:#{u} exceeds column width #{width}" if w < 1
        else
          w = width
        end

        empty = ' ' * w
        "#{empty}#{source}"
      end
    end
  end
end