# Unit tests for the LSM‑Tree implementation using Ruby's built‑in Test::Unit.

require 'test/unit'
require_relative 'core'

class TestLSMTree < Test::Unit::TestCase
  def setup
    @lsm = LSMTree.new(memtable_capacity: 3, run_limit: 2)
  end

  def test_basic_put_get
    @lsm.put('a', 1).put('b', 2)
    assert_equal(1, @lsm.get('a'))
    assert_equal(2, @lsm.get('b'))
    assert_nil(@lsm.get('c'))
  end

  def test_memtable_flush
    @lsm.put('x', 10).put('y', 20).put('z', 30) # triggers flush (capacity 3)
    assert_equal(1, @lsm.run_count)
    assert_equal(0, @lsm.memtable_size)
    assert_equal(10, @lsm.get('x'))
  end

  def test_delete_tombstone
    @lsm.put('k', 100).delete('k')
    assert_nil(@lsm.get('k'))
    # Ensure tombstone survives flush and compaction
    @lsm.put('a', 1).put('b', 2) # cause flush
    assert_nil(@lsm.get('k'))
  end

  def test_compaction
    # Fill enough runs to trigger compaction (run_limit = 2)
    6.times { |i| @lsm.put("key#{i}", i) } # each 3 puts cause a flush => 2 runs
    assert_equal(2, @lsm.run_count)
    @lsm.put('extra', 99) # causes third run -> compaction
    assert_equal(1, @lsm.run_count)
    # Verify data integrity after compaction
    (0..5).each { |i| assert_equal(i, @lsm.get("key#{i}")) }
    assert_equal(99, @lsm.get('extra'))
  end

  def test_overwrite_and_tombstone_resolution
    @lsm.put('u', 5)
    @lsm.put('u', 6) # newer value
    assert_equal(6, @lsm.get('u'))
    @lsm.delete('u')
    assert_nil(@lsm.get('u'))
    # Flush and ensure tombstone wins over older value
    @lsm.put('v', 1).put('w', 2) # cause flush
    assert_nil(@lsm.get('u'))
  end

  def test_binary_search_in_sstable
    sstable = SSTable.new([['a', 1, 1], ['b', 2, 2], ['c', nil, 3]])
    assert_equal([1, 1], sstable.get('a'))
    assert_equal([2, 2], sstable.get('b'))
    assert_equal([nil, 3], sstable.get('c'))
    assert_nil(sstable.get('d'))
  end
end

# Entry point for manual execution
if __FILE__ == $0
  puts "Running LSM‑Tree self‑test suite..."
  Test::Unit::AutoRunner.run
end
