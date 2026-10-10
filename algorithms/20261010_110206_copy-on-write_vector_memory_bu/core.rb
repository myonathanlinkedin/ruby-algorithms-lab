# Copy-on-Write Vector implementation
# Provides a dynamic array with shared underlying storage until a write occurs.

class CowVector
  # Internal buffer class holding the actual array and a reference count.
  class Buffer
    attr_accessor :data, :refcount

    def initialize(data = [])
      @data = data
      @refcount = 1
    end
  end

  # Create a new vector, optionally from an existing Ruby Array.
  def initialize(initial = [])
    @buffer = Buffer.new(initial.dup)
  end

  # Return the number of elements.
  def size
    @buffer.data.size
  end
  alias length size

  # Index read – raises IndexError for out-of-bounds.
  def [](index)
    idx = normalize_index(index)
    @buffer.data[idx]
  end

  # Index write – triggers copy-on-write if buffer is shared.
  def []=(index, value)
    idx = normalize_index(index)
    ensure_unique_buffer!
    @buffer.data[idx] = value
    self
  end

  # Append an element to the end of the vector.
  def push(value)
    ensure_unique_buffer!
    @buffer.data << value
    self
  end
  alias << push

  # Remove and return the last element; raises IndexError if empty.
  def pop
    raise IndexError, "pop from empty vector" if empty?
    ensure_unique_buffer!
    @buffer.data.pop
  end

  # Return true if the vector contains no elements.
  def empty?
    @buffer.data.empty?
  end

  # Return a shallow Ruby Array copy of the contents.
  def to_a
    @buffer.data.dup
  end

  # Duplicate the vector – shares the underlying buffer (copy-on-write).
  def dup
    @buffer.refcount += 1
    copy = self.class.allocate
    copy.instance_variable_set(:@buffer, @buffer)
    copy
  end
  alias clone dup

  # Equality based on elementwise comparison.
  def ==(other)
    return false unless other.is_a?(CowVector)
    to_a == other.to_a
  end

  # Inspect for debugging.
  def inspect
    "#<CowVector #{to_a.inspect}>"
  end

  private

  # Ensure the internal buffer is unique before a mutating operation.
  def ensure_unique_buffer!
    return if @buffer.refcount == 1
    # Decrement refcount of shared buffer.
    @buffer.refcount -= 1
    # Create a private copy.
    @buffer = Buffer.new(@buffer.data.dup)
  end

  # Convert negative indices and validate bounds.
  def normalize_index(index)
    raise TypeError, "index must be Integer" unless index.is_a?(Integer)
    idx = index
    idx += size if idx < 0
    raise IndexError, "index #{index} out of bounds" unless idx.between?(0, size - 1)
    idx
  end
end
