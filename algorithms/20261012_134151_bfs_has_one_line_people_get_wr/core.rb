require 'set'

# Immutable Graph representation using adjacency lists.
# Supports directed or undirected edges.
class Graph
  # Initialize an empty graph.
  # directed: true for directed graph, false for undirected (default).
  def initialize(directed: false)
    @directed = directed
    @adj = Hash.new { |h, k| h[k] = [] }
  end

  # Add a vertex to the graph. No effect if already present.
  def add_vertex(v)
    @adj[v] = [] unless @adj.key?(v)
    self
  end

  # Add an edge from +src+ to +dst+.
  # For undirected graphs, adds the reciprocal edge automatically.
  def add_edge(src, dst)
    add_vertex(src)
    add_vertex(dst)
    @adj[src] << dst
    @adj[dst] << src unless @directed
    self
  end

  # Return a shallow copy of adjacency list for external inspection.
  def adjacency
    @adj.transform_values(&:dup)
  end

  # Breadth‑First Search.
  # Returns an array of vertices in the order they are visited.
  # The start vertex must exist in the graph; otherwise ArgumentError is raised.
  # The algorithm marks a vertex as visited **when it is enqueued**, which
  # guarantees each vertex is processed at most once and prevents infinite loops
  # on cyclic graphs.
  def bfs(start)
    raise ArgumentError, "Start vertex #{start.inspect} not in graph" unless @adj.key?(start)

    visited = Set.new
    queue   = []
    order   = []

    visited << start
    queue << start

    until queue.empty?
      v = queue.shift
      order << v
      @adj[v].each do |nbr|
        next if visited.include?(nbr)
        visited << nbr
        queue << nbr
      end
    end

    order
  end
end
