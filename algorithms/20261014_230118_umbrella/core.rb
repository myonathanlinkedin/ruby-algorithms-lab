# frozen_string_literal: true

# Umbrella (Disjoint Set Union) implementation with path compression and union by rank.
# Provides near-constant amortized time for find and union operations.
class Umbrella
  # Initialize the structure with an optional enumerable of elements.
  # Each element becomes a singleton set.
  #
  # Time: O(n) where n is the number of initial elements.
  # Space: O(n)
  def initialize(elements = [])
    @parent = []          # parent[i] = index of parent of i; root points to itself
    @rank   = []          # rank[i] = approximate tree depth
    @index  = {}          # element => index mapping
    elements.each { |e| make_set(e) }
  end

  # Create a new singleton set containing +element+.
  # Raises ArgumentError if the element already exists.
  #
  # Time: O(1)
  def make_set(element)
    raise ArgumentError, "Element already present: #{element.inspect}" if @index.key?(element)

    idx = @parent.size
    @parent << idx
    @rank   << 0
    @index[element] = idx
    self
  end

  # Find the representative (root) of the set containing +element+.
  # Implements path compression.
  #
  # Time: Amortized O(α(n)) where α is the inverse Ackermann function.
  def find(element)
    idx = @index.fetch(element) { raise ArgumentError, "Unknown element: #{element.inspect}" }
    root = find_root(idx)
    compress_path(idx, root)
    element_at(root)
  end

  # Union the sets containing +a+ and +b+.
  # Returns true if a merge happened, false if they were already in the same set.
  #
  # Time: Amortized O(α(n))
  def union(a, b)
    ra = @index.fetch(a) { raise ArgumentError, "Unknown element: #{a.inspect}" }
    rb = @index.fetch(b) { raise ArgumentError, "Unknown element: #{b.inspect}" }

    ra_root = find_root(ra)
    rb_root = find_root(rb)
    return false if ra_root == rb_root

    # Union by rank
    if @rank[ra_root] < @rank[rb_root]
      @parent[ra_root] = rb_root
    elsif @rank[ra_root] > @rank[rb_root]
      @parent[rb_root] = ra_root
    else
      @parent[rb_root] = ra_root
      @rank[ra_root] += 1
    end
    true
  end

  # Returns true if +a+ and +b+ are in the same set.
  #
  # Time: Amortized O(α(n))
  def connected?(a, b)
    find(a) == find(b)
  end

  # Returns the total number of distinct sets currently stored.
  #
  # Time: O(n) (full scan). Typically called rarely.
  def set_count
    roots = {}
    @parent.each_index { |i| roots[find_root(i)] = true }
    roots.size
  end

  # Returns an array of arrays, each inner array being the elements of a set.
  #
  # Time: O(n)
  def groups
    groups_hash = Hash.new { |h, k| h[k] = [] }
    @index.each do |elem, idx|
      root = find_root(idx)
      groups_hash[root] << elem
    end
    groups_hash.values
  end

  private

  # Internal: find root index without path compression.
  def find_root(idx)
    while @parent[idx] != idx
      idx = @parent[idx]
    end
    idx
  end

  # Internal: compress the path from start index to root.
  def compress_path(start_idx, root_idx)
    while @parent[start_idx] != root_idx
      parent = @parent[start_idx]
      @parent[start_idx] = root_idx
      start_idx = parent
    end
  end

  # Internal: retrieve the element stored at a given root index.
  def element_at(root_idx)
    @index.key(root_idx) || @index.each { |k, v| return k if v == root_idx }
  end
end
