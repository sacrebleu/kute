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

      # render this column's name according to the layout rules
      def title
        v = name.to_s.capitalize
        align_right? ? rjust(v) : ljust(v)
      end

      # render the target according to this column's layout rules
      def render(target)
        align_right? ? rjust(target) : ljust(target)
      end

      def rjust(source)
        w = width - $pastel.strip(source).length
        raise "[#{source}] exceeds column width" if w < 1

        empty = ' ' * w
        "#{empty}#{source}"
      end

      def ljust(source)
        w = width - $pastel.strip(source).length
        raise "[#{source}] exceeds column width" if w < 1

        empty = ' ' * w
        "#{source}#{empty}"
      end

      def trim(s)
        s[0..width-2]
      end
    end
  end
end