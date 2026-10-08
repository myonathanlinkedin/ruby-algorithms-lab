require_relative 'types'
require 'set'

class DAG
  attr_reader :nodes, :adjacency, :indegree

  # Initializes an empty directed acyclic graph.
  # Time: O(1) | Space: O(1)
  def initialize
    @nodes = {}                         # id => Node
    @adjacency = Hash.new { |h, k| h[k] = Set.new } # id => Set of neighbor ids
    @indegree = Hash.new(0)             # id => incoming edge count
  end

  # Adds a node with the given identifier.
  # Raises ArgumentError if the node already exists.
  # Time: O(1) | Space: O(1) (per node)
  def add_node(id)
    raise ArgumentError, "Node #{id} already exists" if @nodes.key?(id)

    @nodes[id] = Node.new(id)
    @adjacency[id]          # ensures entry exists
    @indegree[id] = 0
    self
  end

  # Adds a directed edge from +from_id+ to +to_id+.
  # Both nodes must already exist; self‑loops are prohibited.
  # Duplicate edges are ignored.
  # Time: O(1) amortized | Space: O(1) per edge
  def add_edge(from_id, to_id)
    unless @nodes.key?(from_id) && @nodes.key?(to_id)
      raise ArgumentError, "Both nodes must exist before adding edge"
    end
    raise ArgumentError, "Self‑loop not allowed (#{from_id} → #{to_id})" if from_id == to_id

    unless @adjacency[from_id].include?(to_id)
      @adjacency[from_id] << to_id
      @indegree[to_id] += 1
    end
    self
  end

  # Returns a topological ordering of the node identifiers using Kahn's algorithm.
  # Raises CycleError if the graph contains a cycle.
  # Time: O(V + E) | Space: O(V) for the indegree copy and queue
  def topological_sort
    indegree_copy = @indegree.dup
    queue = []

    @nodes.each_key { |id| queue << id if indegree_copy[id] == 0 }

    order = []
    until queue.empty?
      n = queue.shift
      order << n
      @adjacency[n].each do |m|
        indegree_copy[m] -= 1
        queue << m if indegree_copy[m] == 0
      end
    end

    if order.size != @nodes.size
      raise CycleError, "Graph contains a cycle"
    end

    order
  end

  # Boolean check for cycles using topological_sort.
  # Time: O(V + E) | Space: O(V)
  def has_cycle?
    !!(begin
          topological_sort
          false
        rescue CycleError
          true
        end)
  end

  # Executes a client‑side runtime by yielding each Node in topological order.
  # Requires a block; raises ArgumentError otherwise.
  # Time: O(V + E) | Space: O(V)
  def execute(&block)
    raise ArgumentError, "Block required for execution" unless block_given?
    topological_sort.each { |node_id| block.call(@nodes[node_id]) }
  end
end
