# frozen_string_literal: true

# Copy‑On‑Write Vector implementation.
# Provides an array‑like container with shared immutable buffers.
# Mutating operations trigger a private copy when the underlying buffer
# is shared (reference count > 1). All operations run in O(1) amortized
# time, except when a copy or growth occurs, which is O(n).

module CowVectorModule
  # Internal buffer holding the raw storage and a reference count.
  class Buffer
    attr_reader :data, :refcount

    def initialize(data = [], refcount = 1)
      @data = data
      @refcount = refcount
    end

    # Increment reference count (called when a vector is cloned).
    def inc_ref
      @refcount += 1
    end

    # Decrement reference count (called when a vector discards the buffer).
    # Returns the new count.
    def dec_ref
      @refcount -= 1
      @refcount
    end

    # True if this buffer is owned exclusively.
    def unique?
      @refcount == 1
    end

    # Produce a deep copy of the underlying array with a fresh refcount.
    def duplicate
      Buffer.new(@data.clone, 1)
    end
  end

  # Public Copy‑On‑Write vector class.
  class CowVector
    include Enumerable

    # Create a new vector. +initial+ may be any Enumerable.
    def initialize(initial = [])
      arr = initial.to_a
      @buffer = Buffer.new(arr.clone, 1)
      @size = arr.size
    end

    # Number of stored elements.
    def size
      @size
    end
    alias length size

    # Current capacity of the underlying storage.
    def capacity
      @buffer.data.size
    end

    # Index access (supports negative indices like Array#[]).
    def [](index)
      idx = normalize_index(index)
      return nil if idx >= @size || idx < 0

      @buffer.data[idx]
    end

    # Index assignment – triggers copy‑on‑write if needed.
    def []=(index, value)
      idx = normalize_index(index)
      raise IndexError, "index #{index} out of bounds" if idx >= @size || idx < 0

      ensure_unique!
      @buffer.data[idx] = value
      value
    end

    # Append +value+ to the end of the vector.
    def push(value)
      ensure_unique!
      grow if @size == capacity
      @buffer.data[@size] = value
      @size += 1
      self
    end
    alias << push

    # Remove and return the last element.
    def pop
      raise IndexError, 'pop from empty vector' if @size.zero?

      ensure_unique!
      val = @buffer.data[@size - 1]
      @buffer.data[@size - 1] = nil
      @size -= 1
      val
    end

    # Return a shallow copy that shares the underlying buffer.
    def clone
      # Ruby's clone invokes initialize_copy; we delegate to it.
      super
    end

    # Convert to a plain Ruby Array (copies the data up to @size).
    def to_a
      @buffer.data[0, @size].clone
    end

    # Iterate over elements (required by Enumerable).
    def each(&block)
      return enum_for(:each) unless block_given?

      i = 0
      while i < @size
        block.call(@buffer.data[i])
        i += 1
      end
      self
    end

    # Equality based on elementwise comparison.
    def ==(other)
      return false unless other.is_a?(CowVector) || other.is_a?(Array)

      to_a == other.to_a
    end

    protected

    # Ruby calls this after #clone or #dup.
    def initialize_copy(source)
      super
      @buffer = source.instance_variable_get(:@buffer)
      @size   = source.instance_variable_get(:@size)
      @buffer.inc_ref
    end

    private

    # Ensure the current vector has exclusive ownership of its buffer.
    def ensure_unique!
      return if @buffer.unique?

      old = @buffer
      @buffer = old.duplicate
      old.dec_ref
    end

    # Grow capacity (doubling strategy, minimum 1).
    def grow
      new_cap = [capacity * 2, 1].max
      new_data = @buffer.data[0, @size] + Array.new(new_cap - @size)
      @buffer = Buffer.new(new_data, 1)
    end

    # Normalise negative indices like Array#[] does.
    def normalize_index(idx)
      idx = idx + @size if idx.negative?
      idx
    end
  end
end
