class Dora
  # Double-ended queue with O(1) amortized push/pop on both ends
  # and O(1) random access. Implements a circular buffer that
  # grows geometrically when full.

  DEFAULT_CAPACITY = 8

  def initialize(initial_capacity = DEFAULT_CAPACITY)
    raise ArgumentError, "capacity must be positive" unless initial_capacity > 0
    @capacity = initial_capacity
    @buffer   = Array.new(@capacity)
    @head     = 0          # points to first element
    @tail     = 0          # points to slot after last element
    @size     = 0
  end

  # Public query methods ----------------------------------------------------
  def size
    @size
  end

  def empty?
    @size.zero?
  end

  # Push operations ---------------------------------------------------------
  def push_back(value)
    ensure_capacity!
    @buffer[@tail] = value
    @tail = (@tail + 1) % @capacity
    @size += 1
    self
  end

  def push_front(value)
    ensure_capacity!
    @head = (@head - 1) % @capacity
    @buffer[@head] = value
    @size += 1
    self
  end

  # Pop operations ----------------------------------------------------------
  def pop_back
    raise IndexError, "pop_back from empty Dora" if empty?
    @tail = (@tail - 1) % @capacity
    value = @buffer[@tail]
    @buffer[@tail] = nil
    @size -= 1
    value
  end

  def pop_front
    raise IndexError, "pop_front from empty Dora" if empty?
    value = @buffer[@head]
    @buffer[@head] = nil
    @head = (@head + 1) % @capacity
    @size -= 1
    value
  end

  # Random access -----------------------------------------------------------
  def get(index)
    check_index!(index)
    @buffer[internal_index(index)]
  end

  def set(index, value)
    check_index!(index)
    @buffer[internal_index(index)] = value
    self
  end

  # Enumerable support ------------------------------------------------------
  include Enumerable

  def each
    return enum_for(:each) unless block_given?
    @size.times { |i| yield get(i) }
    self
  end

  # Inspection --------------------------------------------------------------
  def to_a
    map { |e| e }
  end

  def inspect
    "#<Dora size=#{@size} elements=#{to_a.inspect}>"
  end

  private

  # Translate a logical index (0..size-1) to a physical slot in @buffer.
  def internal_index(index)
    (@head + index) % @capacity
  end

  def check_index!(index)
    unless index.is_a?(Integer) && index.between?(0, @size - 1)
      raise IndexError, "index #{index} out of bounds (size=#{@size})"
    end
  end

  # Grow the underlying array when it becomes full.
  def ensure_capacity!
    return if @size < @capacity
    new_capacity = @capacity * 2
    new_buffer = Array.new(new_capacity)
    @size.times do |i|
      new_buffer[i] = @buffer[internal_index(i)]
    end
    @buffer = new_buffer
    @capacity = new_capacity
    @head = 0
    @tail = @size
  end
end
