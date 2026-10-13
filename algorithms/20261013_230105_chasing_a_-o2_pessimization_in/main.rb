# frozen_string_literal: true

require 'test/unit'
require_relative 'engine'

# Unit‑test suite for DisjointSet.
class TestDisjointSet < Test::Unit::TestCase
  def setup
    @ds = DisjointSet.new
    # Create a modest universe of elements.
    (1..10).each { |i| @ds.make_set(i) }
  end

  def test_initial_state
    (1..10).each do |i|
      assert_equal(i, @ds.find(i).value, "Element #{i} should be its own root initially")
    end
  end

  def test_simple_union_and_find
    @ds.union(1, 2)
    assert_true(@ds.connected?(1, 2), '1 and 2 must be connected after union')
    assert_equal(@ds.find(1), @ds.find(2), 'Roots must be identical after union')
  end

  def test_transitive_union
    @ds.union(1, 2)
    @ds.union(2, 3)
    assert_true(@ds.connected?(1, 3), 'Union should be transitive')
    assert_equal(@ds.find(1), @ds.find(3), 'All three should share the same root')
  end

  def test_union_by_rank_preserves_shallow_tree
    # Build a chain of unions: (1,2), (3,4), (1,3) => two trees of rank 1 merged.
    @ds.union(1, 2)
    @ds.union(3, 4)
    root_before = @ds.find(1)
    @ds.union(1, 3)
    root_after = @ds.find(1)

    # After merging two rank‑1 trees, the resulting root rank should be 2.
    assert_equal(2, root_after.rank, 'Root rank must be 2 after merging two rank‑1 trees')
    # Path compression ensures all nodes point directly to the new root.
    [1, 2, 3, 4].each do |i|
      assert_equal(root_after, @ds.find(i), "Element #{i} should compress to the new root")
    end
  end

  def test_invalid_operations
    assert_raise(KeyError) { @ds.find(999) }
    assert_raise(ArgumentError) { @ds.make_set(nil) }
  end

  def test_large_random_unions
    # Stress test with 1000 elements and random unions.
    large_ds = DisjointSet.new
    (1..1000).each { |i| large_ds.make_set(i) }

    rng = Random.new(42)
    500.times do
      a = rng.rand(1..1000)
      b = rng.rand(1..1000)
      large_ds.union(a, b)
    end

    # Verify that find never raises and that connected? is symmetric.
    (1..1000).each do |i|
      assert_nothing_raised { large_ds.find(i) }
    end

    100.times do
      a = rng.rand(1..1000)
      b = rng.rand(1..1000)
      assert_equal(large_ds.connected?(a, b), large_ds.connected?(b, a),
                   'connected? must be symmetric')
    end
  end
end

# Demo execution block (runs when file is executed directly)
if __FILE__ == $PROGRAM_NAME
  puts 'Running DisjointSet demo...'

  ds = DisjointSet.new
  %w[a b c d e].each { |label| ds.make_set(label) }

  ds.union('a', 'b')
  ds.union('c', 'd')
  ds.union('b', 'c')

  puts "Are 'a' and 'd' connected? #{ds.connected?('a', 'd')}"
  puts "Root of 'e' is '#{ds.find('e').value}' (should be itself)."

  # Expected output:
  # Are 'a' and 'd' connected? true
  # Root of 'e' is 'e' (should be itself).
end
