# frozen_string_literal: true

# MinHeap implements a binary heap with a customizable comparator.
# It provides O(log n) push and pop operations.
class MinHeap
  def initialize(&comparator)
    @comparator = comparator || proc { |a, b| a <=> b }
    @data = []
  end

  def push(item)
    @data << item
    sift_up(@data.size - 1)
    self
  end

  def pop
    return nil if empty?

    top = @data[0]
    last = @data.pop
    unless empty?
      @data[0] = last
      sift_down(0)
    end
    top
  end

  def empty?
    @data.empty?
  end

  def size
    @data.size
  end

  private

  def sift_up(idx)
    while idx.positive?
      parent = (idx - 1) / 2
      break if compare(@data[parent], @data[idx]) <= 0

      @data[parent], @data[idx] = @data[idx], @data[parent]
      idx = parent
    end
  end

  def sift_down(idx)
    size = @data.size
    loop do
      left = idx * 2 + 1
      right = left + 1
      smallest = idx

      smallest = left if left < size && compare(@data[left], @data[smallest]) < 0
      smallest = right if right < size && compare(@data[right], @data[smallest]) < 0

      break if smallest == idx

      @data[smallest], @data[idx] = @data[idx], @data[smallest]
      idx = smallest
    end
  end

  def compare(a, b)
    @comparator.call(a, b)
  end
end

# Conductor merges multiple sorted enumerables into a single sorted stream.
# It guarantees O(N log k) time where N is total elements and k is number of streams.
class Conductor
  include Enumerable

  # Adds a new sorted enumerable to the conductor.
  # The enumerable is not consumed until iteration begins.
  #
  # @param enum [Enumerable] a sorted enumerable (e.g., Array, Enumerator)
  def add_stream(enum)
    raise ArgumentError, 'Stream must respond to each' unless enum.respond_to?(:each)

    @streams << enum.each
    self
  end

  # Creates a new conductor instance.
  def initialize
    @streams = []
  end

  # Iterates over the merged, sorted elements.
  #
  # @yieldparam item the next smallest element across all streams
  def each
    return enum_for(:each) unless block_given?

    heap = MinHeap.new { |a, b| a[0] <=> b[0] } # compare by value

    @streams.each_with_index do |enumerator, idx|
      begin
        first = enumerator.next
        heap.push([first, idx, enumerator])
      rescue StopIteration
        # Empty stream – ignore
      end
    end

    until heap.empty?
      value, idx, enumerator = heap.pop
      yield value
      begin
        nxt = enumerator.next
        heap.push([nxt, idx, enumerator])
      rescue StopIteration
        # Stream exhausted
      end
    end
  end

  # Returns an array containing the merged result.
  #
  # @return [Array] merged, sorted elements
  def to_a
    each.to_a
  end
end
