# frozen_string_literal: true

require_relative 'core'
require 'minitest/autorun'

# Unit test suite for Umbrella (Disjoint Set Union)
class TestUmbrella < Minitest::Test
  def setup
    @elements = %w[a b c d e f g]
    @dsu = Umbrella.new(@elements)
  end

  def test_initial_sets_are_singletons
    @elements.each do |e|
      assert_equal e, @dsu.find(e), "Element #{e} should be its own representative initially"
    end
    assert_equal @elements.size, @dsu.set_count
  end

  def test_union_and_connected
    @dsu.union('a', 'b')
    @dsu.union('b', 'c')
    assert @dsu.connected?('a', 'c')
    refute @dsu.connected?('a', 'd')
    assert_equal 6, @dsu.set_count
  end

  def test_union_idempotence
    @dsu.union('x', 'y') rescue nil # unknown elements raise
    assert_raises(ArgumentError) { @dsu.union('a', 'unknown') }
    @dsu.union('a', 'b')
    assert @dsu.union('a', 'b'), "Union should return true on first merge"
    refute @dsu.union('a', 'b'), "Union should return false when already merged"
  end

  def test_make_set_duplicate
    assert_raises(ArgumentError) { @dsu.make_set('a') }
  end

  def test_find_unknown_element
    assert_raises(ArgumentError) { @dsu.find('unknown') }
  end

  def test_groups_reflect_unions
    @dsu.union('a', 'b')
    @dsu.union('c', 'd')
    @dsu.union('b', 'c')
    groups = @dsu.groups.map { |g| g.sort }.sort
    expected = [
      %w[a b c d].sort,
      %w[e].sort,
      %w[f].sort,
      %w[g].sort
    ].map(&:sort).sort
    assert_equal expected, groups
  end

  def test_set_count_after_complex_unions
    pairs = [['a', 'b'], ['c', 'd'], ['e', 'f'], ['b', 'c'], ['f', 'g']]
    pairs.each { |x, y| @dsu.union(x, y) }
    assert_equal 2, @dsu.set_count
    assert @dsu.connected?('a', 'd')
    assert @dsu.connected?('e', 'g')
    refute @dsu.connected?('a', 'e')
  end
end

# Demonstration entrypoint (executed when file is run directly)
if __FILE__ == $PROGRAM_NAME
  puts "=== Umbrella (Disjoint Set Union) Demo ==="
  demo = Umbrella.new((1..10).to_a)
  demo.union(1, 2)
  demo.union(2, 3)
  demo.union(4, 5)
  demo.union(6, 7)
  demo.union(7, 8)
  demo.union(8, 9)
  puts "Groups after unions:"
  demo.groups.each_with_index do |group, idx|
    puts "  Set #{idx + 1}: #{group.sort.inspect}"
  end
  puts "Is 1 connected to 3? #{demo.connected?(1, 3)}"
  puts "Is 1 connected to 5? #{demo.connected?(1, 5)}"
  puts "Total distinct sets: #{demo.set_count}"
end
