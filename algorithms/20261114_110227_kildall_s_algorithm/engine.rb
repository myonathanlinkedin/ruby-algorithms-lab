# Core implementation of Kildall's data‑flow analysis algorithm.

require_relative 'types'

# KildallAnalysis performs a monotone data‑flow analysis on a CFG.
# It supports forward (default) and backward analyses.
class KildallAnalysis
  attr_reader :cfg, :lattice, :direction

  # direction: :forward or :backward
  def initialize(cfg:, lattice:, direction: :forward)
    @cfg = cfg
    @lattice = lattice
    @direction = direction
    validate!
    initialize_node_values!
  end

  # Executes the worklist algorithm until a fixed point is reached.
  def run
    worklist = initial_worklist

    until worklist.empty?
      node = worklist.shift
      old_out = node.out_val

      # Compute IN as meet over appropriate neighbours.
      incoming = if forward?
                   node.pred
                 else
                   node.succ
                 end

      node.in_val = if incoming.empty?
                      lattice.bottom
                    else
                      incoming.map { |n| n.out_val }.reduce(lattice.top) { |acc, val| lattice.meet.call(acc, val) }
                    end

      # Apply transfer function to obtain new OUT.
      node.out_val = node.transfer.call(node.in_val)

      # If OUT changed, propagate to neighbours.
      if node.out_val != old_out
        neighbours = if forward?
                       node.succ
                     else
                       node.pred
                     end
        neighbours.each { |nbr| worklist << nbr unless worklist.include?(nbr) }
      end
    end
    self
  end

  private

  def forward?
    @direction == :forward
  end

  def validate!
    unless [:forward, :backward].include?(@direction)
      raise ArgumentError, "Direction must be :forward or :backward"
    end
  end

  # Initializes IN/OUT of each node to lattice.bottom.
  def initialize_node_values!
    @cfg.nodes.each_value do |node|
      node.in_val = lattice.bottom
      node.out_val = lattice.bottom
    end
  end

  # For forward analysis, start with entry nodes; for backward, exit nodes.
  def initial_worklist
    if forward?
      @cfg.entry_nodes.dup
    else
      @cfg.exit_nodes.dup
    end
  end
end
