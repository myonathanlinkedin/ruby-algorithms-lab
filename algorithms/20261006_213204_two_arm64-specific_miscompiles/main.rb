require 'minitest/autorun'
require 'benchmark'
require_relative 'core'

class TestMiscompileDemo < Minitest::Test
  def setup
    @empty = CurlBug::MiscompileDemo.new("")
    @sample = CurlBug::MiscompileDemo.new("The quick brown fox jumps over the lazy dog")
    @pattern = CurlBug::MiscompileDemo.new("\x00" * 8) # all zeros
  end

  def test_checksum_empty
    assert_equal 0, @empty.checksum
  end

  def test_checksum_known
    # Pre‑computed checksum for the sample string.
    expected = @sample.instance_variable_get(:@data).bytes.reduce(0) { |s, b| (s + b) & CurlBug::MiscompileDemo::MASK_64 }
    assert_equal expected, @sample.checksum
  end

  def test_rotate_left_basic
    demo = CurlBug::MiscompileDemo.new("")
    assert_equal 0x8000000000000001, demo.rotate_left(0x0000000000000001, 1)
    assert_equal 0x0000000000000001, demo.rotate_left(0x8000000000000000, 1)
  end

  def test_complex_hash_consistency
    h1 = @sample.complex_hash
    h2 = CurlBug::MiscompileDemo.new(@sample.instance_variable_get(:@data)).complex_hash
    assert_equal h1, h2
  end

  def test_low32_zero
    assert @pattern.low32_zero?, "All‑zero data should have low 32 bits zero"
    refute @sample.low32_zero?, "Sample data should not have low 32 bits zero"
  end
end

# Simple benchmark to illustrate performance characteristics.
if __FILE__ == $0
  data = "a" * 10_000_000
  demo = CurlBug::MiscompileDemo.new(data)

  puts "Running benchmarks (Ruby #{RUBY_VERSION})..."
  Benchmark.bm(20) do |x|
    x.report("checksum:")      { demo.checksum }
    x.report("rotate_left:")   { 100_000.times { demo.rotate_left(0x123456789abcdef0, 13) } }
    x.report("complex_hash:")  { demo.complex_hash }
  end
end
