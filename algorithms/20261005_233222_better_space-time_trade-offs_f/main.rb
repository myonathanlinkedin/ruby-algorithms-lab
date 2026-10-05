require 'minitest/autorun'
require_relative 'engine'

class TestLSMTree < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir
    @lsm = LSMTree.new(
      memtable_limit: 5,
      sstable_dir: @tmp_dir,
      bloom_bits: 2048,
      bloom_hashes: 3,
      compaction_threshold: 3
    )
  end

  def teardown
    FileUtils.remove_entry_secure(@tmp_dir) if Dir.exist?(@tmp_dir)
  end

  def test_put_and_get
    @lsm.put('a', 1)
    @lsm.put('b', 2)
    assert_equal 1, @lsm.get('a')
    assert_equal 2, @lsm.get('b')
    assert_nil @lsm.get('c')
  end

  def test_overwrite
    @lsm.put('x', 10)
    assert_equal 10, @lsm.get('x')
    @lsm.put('x', 20)
    assert_equal 20, @lsm.get('x')
  end

  def test_delete
    @lsm.put('k', 'val')
    assert_equal 'val', @lsm.get('k')
    @lsm.delete('k')
    assert_nil @lsm.get('k')
  end

  def test_flush_and_recovery
    6.times { |i| @lsm.put("key#{i}", i) } # triggers flush (limit=5)
    6.times { |i| assert_equal i, @lsm.get("key#{i}") }
  end

  def test_range_query
    %w[apple banana cherry date].each_with_index do |k, i|
      @lsm.put(k, i)
    end
    result = @lsm.range_query('banana', 'date')
    expected = {
      'banana' => KVPair.new('banana', 1),
      'cherry' => KVPair.new('cherry', 2),
      'date'   => KVPair.new('date', 3)
    }
    assert_equal expected.keys.sort, result.keys.sort
    expected.each do |k, v|
      assert_equal v.value, result[k].value
    end
  end

  def test_compaction
    # Insert enough to create multiple SSTables and trigger compaction
    20.times do |i|
      @lsm.put("c#{i}", i)
    end
    # After many puts, there should be at most compaction_threshold - 1 SSTables
    assert_operator @lsm.instance_variable_get(:@sstables).size, :<=, 2
    # Verify data integrity
    20.times do |i|
      assert_equal i, @lsm.get("c#{i}")
    end
  end
end
