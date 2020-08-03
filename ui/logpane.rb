module Ui
  class LogPane

    attr_reader :width, :height

    def initialize(tail=100, w = TTY::Screen.width, h=TTY::Screen.height - 3)
      @width = w
      @height = h
      @tail = tail
      @buffer = RingBuffer.new(tail) # hold at most tail entries
      @idx = tail - 1
      @pane_first = back
    end

    def clear
      @buffer.clear
    end

    def push(str)
      @buffer << str
    end
    alias :<< :push

    def last
      @idx = @tail - 1
      @pane_first = back
    end

    def first
      @idx = 0
      self.next
    end

    def previous
      @idx = @pane_first
      @pane_first = back
    end

    def next
      @pane_first = @idx
      @idx = forward
    end

    def range
      [@pane_first, @idx]
    end

    def values
      @buffer.values[@pane_first, @idx]
    end

    private
    def back
      idx = @idx
      n = 0
      while n < height && idx > 0 do
        n += ((@buffer[idx]&.length || 0) / width) + 1
        idx -= 1
      end
      idx
    end

    def forward
      idx = @idx
      n = 0
      while n < height && idx < @tail do
        n += ((@buffer[idx]&.length || 0) / width) + 1
        idx += 1
      end
      idx
    end
  end
end