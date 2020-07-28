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
  alias :<< :push

  def values
    @buffer
  end

  def shift
    @mutex.synchronize(&:remove_element)
  end

  def flush
    values = []
    @mutex.synchronize do
      while not_empty?
        values << remove_element
      end
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
    value, @buffer[@start] = @buffer[@start], nil
    @start = (@start + 1) % @size
    @count -= 1
    value
  end
end