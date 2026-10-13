# frozen_string_literal: true

require_relative 'types'

# Disjoint Set Union (Union‑Find) data structure with path compression
# and union‑by‑rank. Provides near‑constant amortized time operations.
#
# Time Complexity:
#   find   – O(α(n)) amortized
#   union  – O(α(n)) amortized
#   connected? – O(α(n)) amortized
#
# Space Complexity: O(n) for n distinct elements.
class DisjointSet
  # Create a new empty disjoint‑set collection.
  def initialize
    @elements = {}
  end

  # Ensure an element exists for the given key.
  #
  # @param key [Object] identifier for the element
  # @return [DisjointSetElement] the stored element
  def make_set(key)
    raise ArgumentError, 'key cannot be nil' if key.nil?

    @elements[key] ||= DisjointSetElement.new(key)
  end

  # Find the representative (root) of the set containing +key+.
  # Implements path compression.
  #
  # @param key [Object] identifier of the element to locate
  # @return [DisjointSetElement] root element
  def find(key)
    element = @elements[key] || raise(KeyError, "Element #{key.inspect} not found")
    if element.parent != element
      element.parent = find(element.parent.value) # recursive compression
    end
    element.parent
  end

  # Union the sets containing +key1+ and +key2+.
  # Uses union‑by‑rank to keep tree shallow.
  #
  # @param key1 [Object] first element identifier
  # @param key2 [Object] second element identifier
  # @return [void]
  def union(key1, key2)
    root1 = find(key1)
    root2 = find(key2)
    return if root1 == root2

    # Attach smaller rank tree under larger rank tree.
    if root1.rank < root2.rank
      root1.parent = root2
    elsif root1.rank > root2.rank
      root2.parent = root1
    else
      root2.parent = root1
      root1.rank += 1
    end
  end

  # Determine whether +key1+ and +key2+ belong to the same set.
  #
  # @param key1 [Object] first element identifier
  # @param key2 [Object] second element identifier
  # @return [Boolean] true if both are connected
  def connected?(key1, key2)
    find(key1) == find(key2)
  end

  # Expose internal mapping for testing/debugging (read‑only).
  #
  # @return [Hash{Object=>DisjointSetElement}]
  def elements
    @elements.dup.freeze
  end
end
