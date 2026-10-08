require 'minitest/autorun'
require_relative 'core'

class TestCP < Minitest::Test
  def test_fast_scanner
    scanner = CP::FastScanner.new("10 20 hello")
    assert_equal 10, scanner.next_int
    assert_equal 20, scanner.next_int
    assert_equal "hello", scanner.next_str
  end

  def test_modint_operations
    a = CP::ModInt.new(5)
    b = CP::ModInt.new(3)
    assert_equal 8, (a + b).to_i
    assert_equal 2, (a - b).to_i
    assert_equal 15, (a * b).to_i
    assert_equal 5 * CP::ModMath.mod_inv(3) % CP::ModMath::MOD, (a / b).to_i
    assert_equal 125, (a ** 3).to_i
  end

  def test_union_find
    uf = CP::UnionFind.new(5)
    assert uf.union(0, 1)
    refute uf.union(0, 1)
    assert uf.same?(0, 1)
    refute uf.same?(0, 2)
    uf.union(2, 3)
    uf.union(1, 2)
    assert uf.same?(0, 3)
    assert_equal 4, uf.component_size(0)
  end

  def test_fenwick_tree
    ft = CP::FenwickTree.new(5)
    [1, 2, 3, 4, 5].each_with_index { |v, i| ft.add(i, v) }
    assert_equal 15, ft.sum(4)
    assert_equal 6, ft.range_sum(1, 3)
    ft.add(2, -3)
    assert_equal 12, ft.sum(4)
  end

  def test_segment_tree
    arr = [1, 2, 3, 4, 5]
    st = CP::SegmentTree.new(arr)
    assert_equal 15, st.query(0, 5)
    assert_equal 9, st.query(1, 4)
    st.update(2, 10)
    assert_equal 22, st.query(0, 5)
    assert_equal 16, st.query(2, 5)
  end
end

# Demonstration block (executed when running this file directly)
if __FILE__ == $0
  scanner = CP::FastScanner.new
  n = scanner.next_int
  arr = Array.new(n) { scanner.next_int }
  q = scanner.next_int

  ft = CP::FenwickTree.new(n)
  arr.each_with_index { |v, i| ft.add(i, v) }

  st = CP::SegmentTree.new(arr)

  q.times do
    type = scanner.next_int
    case type
    when 1 # point update
      idx = scanner.next_int - 1
      val = scanner.next_int
      delta = val - arr[idx]
      arr[idx] = val
      ft.add(idx, delta)
      st.update(idx, val)
    when 2 # prefix sum query (Fenwick)
      r = scanner.next_int - 1
      puts ft.sum(r)
    when 3 # range sum query (Segment Tree)
      l = scanner.next_int - 1
      r = scanner.next_int
      puts st.query(l, r)
    end
  end
end
