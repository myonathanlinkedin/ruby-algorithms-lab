# frozen_string_literal: true

# Simple immutable edge representation.
Edge = Struct.new(:u, :v, :weight) do
  include Comparable
  def <=>(other) = weight <=> other.weight
  def to_s = "(#{u}-#{v}:#{weight})"
end

# Disjoint‑Set Union (Union‑Find) with path compression and union by rank.
class UnionFind
  def initialize(size)
    @parent = Array.new(size) { |i| i }
    @rank   = Array.new(size, 0)
  end

  # Returns the representative of the set containing +x+.
  def find(x)
    if @parent[x] != x
      @parent[x] = find(@parent[x])
    end
    @parent[x]
  end

  # Unites the sets containing +x+ and +y+.
  # Returns true if a merge happened, false if they were already in the same set.
  def union(x, y)
    xr = find(x)
    yr = find(y)
    return false if xr == yr

    if @rank[xr] < @rank[yr]
      @parent[xr] = yr
    elsif @rank[xr] > @rank[yr]
      @parent[yr] = xr
    else
      @parent[yr] = xr
      @rank[xr] += 1
    end
    true
  end
end

# Kruskal's algorithm implementation.
class Kruskal
  # Computes a Minimum Spanning Tree (MST) for an undirected weighted graph.
  #
  # +edges+:: Array of Edge objects (undirected, weight may be negative).
  # +vertex_count+:: Number of vertices, assumed to be labelled 0...(vertex_count-1).
  #
  # Returns an array of Edge objects that form the MST.
  # Raises ArgumentError if the graph is disconnected.
  def self.minimum_spanning_tree(edges, vertex_count)
    raise ArgumentError, 'vertex count must be non‑negative' if vertex_count < 0

    # Sort edges by non‑decreasing weight.
    sorted = edges.sort
    uf = UnionFind.new(vertex_count)
    mst = []

    sorted.each do |e|
      next if e.u == e.v # ignore self‑loops

      if uf.union(e.u, e.v)
        mst << e
        break if mst.size == vertex_count - 1
      end
    end

    if mst.size != vertex_count - 1
      raise ArgumentError, 'graph is disconnected; MST does not exist'
    end

    mst
  end
end
end
end
