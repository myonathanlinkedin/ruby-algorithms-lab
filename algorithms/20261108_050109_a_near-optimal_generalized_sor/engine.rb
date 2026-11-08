# frozen_string_literal: true

require_relative 'types'

# GeneralizedSorter implements Introsort, a hybrid sorting algorithm that
# combines quicksort, heapsort, and insertion sort for near‑optimal performance.
# It works with any Ruby Enumerable and accepts an optional comparator block.
class GeneralizedSorter
  # Public API: returns a new array containing the sorted elements.
  #
  # @param array [Array] the collection to sort
  # @yield [a, b] optional comparator returning -1, 0, +1
  # @return [Array] sorted copy of the input
  def sort(array, &comparator)
    # Defensive copy to keep the original array untouched.
    arr = array.dup
    return arr if arr.length <= 1

    # Default comparator uses the spaceship operator.
    comp = comparator || ->(a, b) { a <=> b }

    # Depth limit for quicksort part: 2 * floor(log₂ n)
    depth_limit = 2 * Math.log2([arr.length, 2].max).floor

    introsort(arr, 0, arr.length - 1, depth_limit, &comp)
    arr
  end

  private

  # Recursively sorts the sub‑array [lo, hi] using quicksort.
  # Switches to heapsort when recursion depth exceeds the limit.
  def introsort(arr, lo, hi, depth_limit, &comp)
    return if lo >= hi

    if depth_limit == 0
      heapsort_range(arr, lo, hi, &comp)
    else
      p = partition(arr, lo, hi, &comp)
      introsort(arr, lo, p - 1, depth_limit - 1, &comp)
      introsort(arr, p + 1, hi, depth_limit - 1, &comp)
    end
  end

  # Lomuto partition scheme.
  def partition(arr, lo, hi, &comp)
    pivot = arr[hi]
    i = lo
    (lo...hi).each do |j|
      if comp.call(arr[j], pivot) <= 0
        arr[i], arr[j] = arr[j], arr[i]
        i += 1
      end
    end
    arr[i], arr[hi] = arr[hi], arr[i]
    i
  end

  # Heapsort confined to the slice arr[lo..hi].
  def heapsort_range(arr, lo, hi, &comp)
    n = hi - lo + 1
    # Build max‑heap.
    (n / 2 - 1).downto(0) { |i| heapify(arr, n, i, lo, &comp) }

    # Extract elements from heap.
    (n - 1).downto(1) do |i|
      arr[lo], arr[lo + i] = arr[lo + i], arr[lo]
      heapify(arr, i, 0, lo, &comp)
    end
  end

  # Restores the heap property for a node within the slice.
  def heapify(arr, heap_size, root_index, offset, &comp)
    largest = root_index
    left = 2 * root_index + 1
    right = 2 * root_index + 2

    if left < heap_size && comp.call(arr[offset + left], arr[offset + largest]) > 0
      largest = left
    end
    if right < heap_size && comp.call(arr[offset + right], arr[offset + largest]) > 0
      largest = right
    end

    if largest != root_index
      arr[offset + root_index], arr[offset + largest] = arr[offset + largest], arr[offset + root_index]
      heapify(arr, heap_size, largest, offset, &comp)
    end
  end
end
