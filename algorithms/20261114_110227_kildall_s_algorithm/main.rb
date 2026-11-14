# Verification driver with unit tests for Kildall's algorithm.

require 'minitest/autorun'
require_relative 'engine'

# Helper to create a transfer function that adds a symbol to the incoming set.
def add_symbol(sym)
  proc { |in_set| in_set + [sym] }
end

# Helper to create a transfer function that leaves the set unchanged.
def identity
  proc { |in_set| in_set }
end

class TestKildallAnalysis < Minitest::Test
  # Lattice for sets of symbols with union as meet (may‑analysis).
  def set_lattice
    Lattice.new(
      bottom: Set.new,
      top: Set.new, # For may‑analysis, top is also empty; meet is union.
      meet: proc { |a, b| a | b }
    )
  end

  def test_empty_cfg
    cfg = CFG.new
    analysis = KildallAnalysis.new(cfg: cfg, lattice: set_lattice, direction: :forward)
    analysis.run
    assert_empty cfg.nodes
  end

  def test_single_node
    cfg = CFG.new
    n1 = CFGNode.new(id: :n1, transfer: add_symbol(:a))
    cfg.add_node(n1)

    analysis = KildallAnalysis.new(cfg: cfg, lattice: set_lattice, direction: :forward)
    analysis.run

    assert_equal Set[:a], n1.out_val
    assert_equal Set[], n1.in_val
  end

  def test_two_nodes_linear
    cfg = CFG.new
    n1 = CFGNode.new(id: :n1, transfer: add_symbol(:a))
    n2 = CFGNode.new(id: :n2, transfer: add_symbol(:b))
    cfg.add_node(n1)
    cfg.add_node(n2)
    cfg.add_edge(:n1, :n2)

    analysis = KildallAnalysis.new(cfg: cfg, lattice: set_lattice, direction: :forward)
    analysis.run

    assert_equal Set[:a], n1.out_val
    assert_equal Set[:a, :b], n2.out_val
    assert_equal Set[:a], n2.in_val
  end

  def test_cycle
    cfg = CFG.new
    n1 = CFGNode.new(id: :n1, transfer: add_symbol(:a))
    n2 = CFGNode.new(id: :n2, transfer: add_symbol(:b))
    cfg.add_node(n1)
    cfg.add_node(n2)
    cfg.add_edge(:n1, :n2)
    cfg.add_edge(:n2, :n1) # cycle

    analysis = KildallAnalysis.new(cfg: cfg, lattice: set_lattice, direction: :forward)
    analysis.run

    expected = Set[:a, :b]
    assert_equal expected, n1.out_val
    assert_equal expected, n2.out_val
    assert_equal expected, n1.in_val
    assert_equal expected, n2.in_val
  end

  def test_backward_analysis
    # Backward may‑analysis (e.g., live variables)
    cfg = CFG.new
    n1 = CFGNode.new(id: :n1, transfer: proc { |out| out - Set[:x] }) # kill x
    n2 = CFGNode.new(id: :n2, transfer: proc { |out| out + Set[:x] }) # gen x
    cfg.add_node(n1)
    cfg.add_node(n2)
    cfg.add_edge(:n1, :n2) # n1 -> n2

    # For backward analysis, meet is union (may‑analysis)
    lattice = Lattice.new(
      bottom: Set.new,
      top: Set.new, # top is empty for may‑analysis
      meet: proc { |a, b| a | b }
    )

    analysis = KildallAnalysis.new(cfg: cfg, lattice: lattice, direction: :backward)
    analysis.run

    # Expected: after n2, x is live; after n1, x is killed, so live set is empty.
    assert_equal Set[:x], n2.out_val
    assert_equal Set[:x], n2.in_val
    assert_equal Set[], n1.out_val
    assert_equal Set[], n1.in_val
  end
end

if __FILE__ == $0
  # Run the test suite when executed directly.
  Minitest.run
end
