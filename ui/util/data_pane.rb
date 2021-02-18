module Ui
  module Util
    class DataPane
      attr_reader :width, :height

      def initialize(w = TTY::Screen.width, h = TTY::Screen.height - 3, data)
        @width = w
        @height = h
        @buffer = data
      end

      def clear
        @buffer = []
      end

      def push(str)
        @buffer << str
      end
      alias << push

      def idx_last
        @buffer.length - 1 - height
      end

      def last
        @idx = idx_last
      end

      def first
        @idx = 0
      end

      def previous
        @idx -= height
        @idx = 0 if @idx.negative?
      end

      def next
        @idx += height
        @idx = idx_last if @idx > idx_last
      end

      def values
        @buffer[@idx..@idx + height]
      end
    end
  end
end
