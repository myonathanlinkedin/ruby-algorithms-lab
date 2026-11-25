# Domain models, interfaces, and memory structs for the Cop-Win Edge Completion problem.
#
# The problem: Given a graph G and a set of "cop-win" vertices (or a target cop-win property),
# find the minimum number of edges to add to make the graph cop-win (i.e., the cop number is 1).
# A graph is cop-win if and only if it is a daisy (a graph with a dominating vertex whose
# removal leaves a cop-win graph, recursively). Equivalently, a graph is cop-win iff it has
# a cop-win ordering (a vertex ordering where each vertex is dominated by a later vertex).
#
# The parameterized algorithm uses the treewidth of the graph as a parameter.
# We implement a bounded-treewidth DP approach for the edge completion problem.

module CopWin
  # Represents an undirected graph with vertex set {0, 1, ..., n-1}.
  class Graph
    attr_reader :n, :adj

    # @param n [Integer] number of vertices
    # @param edges [Array<Array<Integer>>] list of undirected edges [u, v]
    def initialize(n, edges = [])
      @n = n
      @adj = Array.new(n) { [] }
      edges.each do |u, v|
        raise ArgumentError, "vertex out of range" if u < 0 || u >= n || v < 0 || v >= n
        @adj[u] << v
        @adj[v] << u
      end
      # Deduplicate and sort for determinism
      @adj.each! { |list| list.uniq.sort! }
    end

    # Check if edge (u, v) exists
    def edge?(u, v)
      @adj[u].include?(v)
    end

    # Add an edge (mutates)
    def add_edge(u, v)
      return if edge?(u, v)
      @adj[u] << v
      @adj[v] << u
      @adj[u].sort!
      @adj[v].sort!
    end

    # Return a deep copy
    def clone
      edges = []
      @adj.each_with_index do |neighbors, u|
        neighbors.each do |v|
          edges << [u, v] if u < v
        end
      end
      Graph.new(@n, edges)
    end

    # Return the set of neighbors of vertex u
    def neighbors(u)
      @adj[u]
    end

    # Return the degree of vertex u
    def degree(u)
      @adj[u].size
    end

    # Check if vertex u dominates vertex v (u is adjacent to v and u != v)
    def dominates?(u, v)
      u != v && edge?(u, v)
    end

    # Check if vertex u is a universal vertex (adjacent to all other vertices)
    def universal?(u)
      (0...@n).all? { |v| v != u && edge?(u, v) }
    end

    # Check if the graph is complete
    def complete?
      (0...@n).all? { |u| universal?(u) }
    end

    # Return the list of all edges as [u, v] with u < v
    def edges
      result = []
      (0...@n).each do |u|
        @adj[u].each do |v|
          result << [u, v] if u < v
        end
      end
      result
    end

    # Number of edges
    def edge_count
      edges.size
    end

    # Check if the graph is cop-win using the recursive daisy characterization.
    # A graph is cop-win iff it has a vertex v such that:
    #   1. v is a dominating vertex (adjacent to all other vertices), OR
    #   2. v is a "cop-win" vertex: for every neighbor u of v, u is adjacent to
    #      all vertices that v is adjacent to (i.e., N(u) superset N(v) \ {u}),
    #      and G - v is cop-win.
    #
    # Actually, the correct characterization: A graph G is cop-win iff there exists
    # a vertex v such that v is a "cop-win" vertex, meaning:
    #   - v is adjacent to all vertices in some set, and
    #   - G - v is cop-win, and
    #   - v is a "cop-win" vertex in G, which means v is a dominating vertex of
    #     the "cop-win" subgraph.
    #
    # The standard characterization: G is cop-win iff G has a cop-win ordering.
    # A cop-win ordering is a permutation v1, v2, ..., vn such that for each i,
    # vi is dominated by some vj with j > i (i.e., vi is adjacent to vj).
    #
    # We implement the check via the recursive daisy structure:
    # G is cop-win iff there exists a vertex v such that:
    #   (a) v is a dominating vertex of G (adjacent to all other vertices), and
    #   (b) G - v is cop-win.
    #
    # Wait, that's not quite right either. The correct characterization is:
    # G is cop-win iff there exists a vertex v such that v is a "cop-win" vertex,
    # meaning that v is adjacent to all vertices in G that are not "below" v in
    # the cop-win ordering.
    #
    # Let me use the standard algorithm: G is cop-win iff it has a cop-win ordering.
    # We can check this by repeatedly removing a vertex that is dominated by a
    # remaining vertex. If we can remove all vertices this way, the graph is cop-win.
    #
    # Algorithm:
    #   1. Start with the full graph.
    #   2. While there are vertices remaining:
    #      a. Find a vertex v that is dominated by some other remaining vertex u
    #         (i.e., v is adjacent to u).
    #      b. Remove v from the graph.
    #      c. If no such vertex exists, the graph is not cop-win.
    #   3. If all vertices are removed, the graph is cop-win.
    #
    # This is correct because a cop-win ordering is exactly a sequence of vertex
    # removals where each removed vertex is dominated by a later (remaining) vertex.

    def cop_win?
      remaining = (0...@n).to_a
      while remaining.any?
        # Find a vertex that is dominated by another remaining vertex
        found = false
        remaining.each do |v|
          dominated = remaining.any? { |u| u != v && edge?(v, u) }
          if dominated
            remaining.delete(v)
            found = true
            break
          end
        end
        return false unless found
      end
      true
    end

    # Return a cop-win ordering if the graph is cop-win, else nil.
    # The ordering is a list of vertices in the order they are removed.
    def cop_win_ordering
      remaining = (0...@n).to_a
      ordering = []
      while remaining.any?
        found = false
        remaining.each do |v|
          dominated = remaining.any? { |u| u != v && edge?(v, u) }
          if dominated
            remaining.delete(v)
            ordering << v
            found = true
            break
          end
        end
        return nil unless found
      end
      ordering
    end

    # Check if the graph is a daisy (has a dominating vertex whose removal
    # leaves a cop-win graph). This is a stronger condition than cop-win.
    def daisy?
      (0...@n).each do |v|
        next unless universal?(v)
        subgraph = remove_vertex(v)
        return true if subgraph.cop_win?
      end
      false
    end

    # Remove vertex v and return the induced subgraph on the remaining vertices.
    def remove_vertex(v)
      remaining = (0...@n).to_a - [v]
      new_n = remaining.size
      mapping = {}
      remaining.each_with_index { |old, new| mapping[old] = new }
      new_edges = []
      remaining.each do |u|
        remaining.each do |w|
          next if u >= w
          new_edges << [mapping[u], mapping[w]] if edge?(u, w)
        end
      end
      Graph.new(new_n, new_edges)
    end

    # Return the adjacency matrix as a 2D array of booleans
    def adjacency_matrix
      matrix = Array.new(@n) { Array.new(@n, false) }
      @adj.each_with_index do |neighbors, u|
        neighbors.each { |v| matrix[u][v] = true }
      end
      matrix
    end

    # String representation
    def to_s
      "Graph(n=#{@n}, edges=#{edge_count})"
    end
  end

  # Represents a tree decomposition of a graph.
  # A tree decomposition is a tree T = (B, E) where each node b in B is a
  # "bag" (a subset of vertices) such that:
  #   1. For every vertex v in G, there is a bag containing v.
  #   2. For every edge (u, v) in G, there is a bag containing both u and v.
  #   3. For every vertex v in G, the bags containing v form a connected subtree.
  #
  # The width of a tree decomposition is max(|B| - 1) over all bags B.
  # The treewidth of G is the minimum width over all tree decompositions.
  class TreeDecomposition
    attr_reader :bags, :tree_edges, :vertex_to_bags

    # @param bags [Array<Array<Integer>>] list of bags (each a set of vertices)
    # @param tree_edges [Array<Array<Integer>>] edges of the tree (indices into bags)
    def initialize(bags, tree_edges)
      @bags = bags
      @tree_edges = tree_edges
      @vertex_to_bags = {}
      bags.each_with_index do |bag, i|
        bag.each do |v|
          @vertex_to_bags[v] ||= []
          @vertex_to_bags[v] << i
        end
      end
    end

    # Width of the tree decomposition
    def width
      @bags.map { |bag| bag.size - 1 }.max
    end

    # Check if this is a valid tree decomposition of the given graph
    def valid?(graph)
      # Check 1: every vertex is in some bag
      (0...graph.n).each do |v|
        return false unless @vertex_to_bags.key?(v)
      end

      # Check 2: every edge is in some bag
      graph.edges.each do |u, v|
        found = @bags.any? { |bag| bag.include?(u) && bag.include?(v) }
        return false unless found
      end

      # Check 3: for each vertex, the bags containing it form a connected subtree
      @vertex_to_bags.each do |v, bag_indices|
        return false unless connected_subtree?(bag_indices)
      end

      true
    end

    # Check if the given bag indices form a connected subtree in the tree
    def connected_subtree?(bag_indices)
      return true if bag_indices.size <= 1

      # Build adjacency for the tree
      tree_adj = Hash.new { |h, k| h[k] = [] }
      @tree_edges.each do |u, v|
        tree_adj[u] << v
        tree_adj[v] << u
      end

      # Check connectivity among the specified bag indices
      visited = {}
      queue = [bag_indices.first]
      visited[bag_indices.first] = true
      while queue.any?
        current = queue.shift
        tree_adj[current].each do |neighbor|
          next unless bag_indices.include?(neighbor)
          next if visited[neighbor]
          visited[neighbor] = true
          queue << neighbor
        end
      end

      bag_indices.all? { |idx| visited[idx] }
    end

    # String representation
    def to_s
      "TreeDecomposition(bags=#{@bags.size}, width=#{width})"
    end
  end

  # Represents a solution to the edge completion problem.
  class Solution
    attr_reader :added_edges, :final_graph, :valid

    # @param added_edges [Array<Array<Integer>>] edges that were added
    # @param final_graph [Graph] the resulting graph
    # @param valid [Boolean] whether the solution is valid (final graph is cop-win)
    def initialize(added_edges, final_graph, valid)
      @added_edges = added_edges
      @final_graph = final_graph
      @valid = valid
    end

    # Number of edges added
    def edge_count
      @added_edges.size
    end

    # String representation
    def to_s
      "Solution(added=#{edge_count}, valid=#{@valid})"
    end
  end
end
