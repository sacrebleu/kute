class RingBuffer
  def initialize(size)
    @size = size
    @start = 0
    @count = 0
    @buffer = Array.new(size)
    @mutex = Mutex.new
  end

  def full?
    @count == @size
  end

  def empty?
    @count == 0
  end

  def not_empty?
    !empty?
  end

  def push(value)
    @mutex.synchronize do
      stop = (@start + @count) % @size
      @buffer[stop] = value
      if full?
        @start = (@start + 1) % @size
      else
        @count += 1
      end
      value
    end
  end
  alias << push

  def [](idx)
    @buffer[idx]
  end

  def values(from = 0, to = -1)
    i = from < 0 || from > @buffer.length ? 0 : from
    j = to > (@buffer.length - 1) ? @buffer.length - 1 : to
    @buffer[i..j]
  end

  def shift
    @mutex.synchronize(&:remove_element)
  end

  def flush
    values = []
    @mutex.synchronize do
      values << remove_element while not_empty?
    end
    values
  end

  def clear
    @buffer = Array.new(@size)
    @start = 0
    @count = 0
  end

  private

  def remove_element
    return nil if empty?

    value = @buffer[@start]
    @buffer[@start] = nil
    @start = (@start + 1) % @size
    @count -= 1
    value
  end
end
