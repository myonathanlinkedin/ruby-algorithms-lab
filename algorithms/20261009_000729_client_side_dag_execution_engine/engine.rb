require 'set'
require_relative 'types'

class DAG
  # Public: Create a new directed acyclic graph.
  def initialize
    @nodes = {}               # id => Node
    @adjacency = Hash.new { |h, k| h[k] = Set.new } # id => Set of successor ids
    @indegree = Hash.new(0)   # id => integer indegree count
  end

  # Public: Add a node with a unique identifier.
  #
  # id - Any object that can be used as a hash key (String, Symbol, Integer, etc.)
  #
  # Raises GraphError if a node with the same id already exists.
  # Returns the created Node.
  def add_node(id)
    raise GraphError, "Node #{id.inspect} already exists" if @nodes.key?(id)

    node = Node.new(id)
    @nodes[id] = node
    # Ensure structures are initialized for the new node
    @adjacency[id]   # triggers default Set
    @indegree[id]   # triggers default 0
    node
  end

  # Public: Add a directed edge from +from_id+ to +to_id+.
  #
  # from_id - Identifier of the source node.
  # to_id   - Identifier of the destination node.
  #
  # Raises GraphError if either node does not exist, if the edge creates a self‑loop,
  # or if the edge already exists.
  # Returns true on success.
  def add_edge(from_id, to_id)
    raise GraphError, "Source node #{from_id.inspect} does not exist" unless @nodes.key?(from_id)
    raise GraphError, "Destination node #{to_id.inspect} does not exist" unless @nodes.key?(to_id)
    raise GraphError, "Self‑loop detected on node #{from_id.inspect}" if from_id == to_id
    raise GraphError, "Edge #{from_id.inspect} → #{to_id.inspect} already exists" if @adjacency[from_id].include?(to_id)

    @adjacency[from_id] << to_id
    @indegree[to_id] += 1
    true
  end

  # Public: Compute a topological ordering of the DAG using Kahn's algorithm.
  #
  # Returns an Array of Node objects in a valid topological order.
  # Raises GraphError if the graph contains a cycle.
  def topological_sort
    # Clone indegree map to avoid mutating the original state
    indegree = @indegree.transform_values { |v| v }

    # Initialise queue with nodes of indegree 0
    queue = @nodes.keys.select { |id| indegree[id].zero? }
    order = []

    until queue.empty?
      current_id = queue.shift
      order << @nodes[current_id]

      @adjacency[current_id].each do |succ_id|
        indegree[succ_id] -= 1
        queue << succ_id if indegree[succ_id].zero?
      end
    end

    if order.size != @nodes.size
      raise GraphError, 'Cycle detected: topological sort impossible'
    end

    order
  end

  # Public: Detect whether the current graph contains a cycle.
  #
  # Returns true if a cycle exists, false otherwise.
  def has_cycle?
    begin
      topological_sort
      false
    rescue GraphError
      true
    end
  end

  # Public: Expose the internal node collection (read‑only).
  #
  # Returns an Array of Node objects.
  def nodes
    @nodes.values
  end

  # Public: Expose adjacency list for testing/inspection.
  #
  # Returns a Hash mapping node ids to Sets of successor ids.
  def adjacency
    @adjacency.transform_values { |s| s.dup }
  end
end
