# frozen_string_literal: true

# Simple immutable edge representation
Edge = Struct.new(:u, :v, :weight) do
  include Comparable
  def <=>(other) = weight <=> other.weight
end

# Disjoint Set Union (Union-Find) with path compression & union by rank
class DisjointSet
  def initialize(size)
    @parent = Array.new(size) { |i| i }
    @rank   = Array.new(size, 0)
  end

  def find(x)
    if @parent[x] != x
      @parent[x] = find(@parent[x])
    end
    @parent[x]
  end

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

# Kruskal algorithm encapsulation
class KruskalMST
  attr_reader :edges, :vertex_count

  def initialize(vertex_count, edges)
    @vertex_count = vertex_count
    @edges = edges.map { |e| Edge.new(*e) }
  end

  # Returns [mst_edges, total_weight]
  # Raises RuntimeError if graph is disconnected
  def compute
    sorted = @edges.sort
    ds = DisjointSet.new(@vertex_count)
    mst = []
    total = 0

    sorted.each do |e|
      if ds.union(e.u, e.v)
        mst << e
        total += e.weight
        break if mst.size == @vertex_count - 1
      end
    end

    raise RuntimeError, 'Graph is disconnected' unless mst.size == @vertex_count - 1

    [mst, total]
  end
end
