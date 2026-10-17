# frozen_string_literal: true

# DirectedGraph implements a mutable directed graph with
# topological sorting and cycle detection using Kahn's algorithm.
# It raises DirectedGraph::CycleError when a cycle is present.
class DirectedGraph
  # Custom error raised when a cycle is detected during topological sort.
  class CycleError < StandardError; end

  def initialize
    # adjacency list: vertex => array of outgoing neighbours
    @adj = Hash.new { |h, k| h[k] = [] }
    # set of all vertices (Hash used as set for O(1) lookup)
    @vertices = {}
  end

  # Adds a vertex to the graph. No effect if it already exists.
  #
  # @param v [Object] vertex identifier (must be hashable)
  def add_vertex(v)
    @vertices[v] = true
    @adj[v] # ensure adjacency entry exists
    self
  end

  # Adds a directed edge from +from+ to +to+.
  # Implicitly creates the vertices if they do not exist.
  #
  # @param from [Object] source vertex
  # @param to   [Object] destination vertex
  def add_edge(from, to)
    add_vertex(from)
    add_vertex(to)
    @adj[from] << to
    self
  end

  # Returns an array of all vertices in the graph.
  #
  # @return [Array<Object>]
  def vertices
    @vertices.keys
  end

  # Performs a topological sort.
  #
  # @return [Array<Object>] vertices in topological order
  # @raise  [CycleError] if the graph contains a cycle
  def topological_sort
    indegree = Hash.new(0)
    vertices.each { |v| indegree[v] = 0 }

    @adj.each_value do |neighbors|
      neighbors.each { |v| indegree[v] += 1 }
    end

    # Queue of vertices with zero indegree
    zero_indeg = indegree.each_with_object([]) { |(v, d), arr| arr << v if d.zero? }

    order = []
    until zero_indeg.empty?
      u = zero_indeg.shift
      order << u
      @adj[u].each do |v|
        indegree[v] -= 1
        zero_indeg << v if indegree[v].zero?
      end
    end

    raise CycleError, 'graph contains a cycle' unless order.size == vertices.size

    order
  end
end
end
