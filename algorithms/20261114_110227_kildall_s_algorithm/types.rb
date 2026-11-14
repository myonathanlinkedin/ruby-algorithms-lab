# Data structures for Kildall's algorithm

# Lattice encapsulates the abstract domain, its bottom/top elements,
# and the meet operator (a binary Proc).
class Lattice
  attr_reader :bottom, :top, :meet

  # bottom: the least element (e.g., empty set)
  # top: the greatest element (e.g., universal set)
  # meet: a Proc taking two elements and returning their meet
  def initialize(bottom:, top:, meet:)
    @bottom = bottom
    @top = top
    @meet = meet
  end
end

# CFGNode represents a node in a control‑flow graph.
# Each node holds:
# - an identifier (symbol or integer)
# - successor and predecessor collections
# - a transfer function (Proc) that maps IN -> OUT
# - IN and OUT abstract values (initialized to lattice.bottom)
class CFGNode
  attr_reader :id, :succ, :pred, :transfer
  attr_accessor :in_val, :out_val

  def initialize(id:, transfer:)
    @id = id
    @transfer = transfer
    @succ = []
    @pred = []
    @in_val = nil
    @out_val = nil
  end

  def add_successor(node)
    @succ << node unless @succ.include?(node)
    node.pred << self unless node.pred.include?(self)
  end
end

# CFG aggregates nodes and provides utilities for edge creation.
class CFG
  attr_reader :nodes

  def initialize
    @nodes = {}
  end

  # Adds a node; raises if duplicate id.
  def add_node(node)
    raise ArgumentError, "Node id #{node.id} already exists" if @nodes.key?(node.id)
    @nodes[node.id] = node
  end

  # Convenience to fetch a node by id.
  def [](id)
    @nodes[id]
  end

  # Connects two nodes directed from src_id to dst_id.
  def add_edge(src_id, dst_id)
    src = self[src_id] or raise ArgumentError, "Source node #{src_id} missing"
    dst = self[dst_id] or raise ArgumentError, "Destination node #{dst_id} missing"
    src.add_successor(dst)
  end

  # Returns entry nodes for forward analysis (nodes with no predecessors).
  def entry_nodes
    @nodes.values.select { |n| n.pred.empty? }
  end

  # Returns exit nodes for backward analysis (nodes with no successors).
  def exit_nodes
    @nodes.values.select { |n| n.succ.empty? }
  end
end
