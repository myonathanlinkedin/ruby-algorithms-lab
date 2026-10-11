require_relative 'core'
require 'minitest/autorun'

class TestHuffmanCoder < Minitest::Test
  def setup
    @coder = HuffmanCoder.new
  end

  def test_empty_string
    compressed = @coder.compress('')
    assert_equal '', compressed
    decompressed = @coder.decompress(compressed)
    assert_equal '', decompressed
  end

  def test_single_character
    compressed = @coder.compress('aaaaa')
    decompressed = @coder.decompress(compressed)
    assert_equal 'aaaaa', decompressed
  end

  def test_two_characters
    compressed = @coder.compress('ababa')
    decompressed = @coder.decompress(compressed)
    assert_equal 'ababa', decompressed
  end

  def test_common_string
    text = 'this is an example for huffman coding'
    compressed = @coder.compress(text)
    decompressed = @coder.decompress(compressed)
    assert_equal text, decompressed
  end

  def test_random_string
    text = Array.new(1000) { ('a'..'z').to_a.sample }.join
    compressed = @coder.compress(text)
    decompressed = @coder.decompress(compressed)
    assert_equal text, decompressed
  end
end

if __FILE__ == $0
  coder = HuffmanCoder.new
  sample = 'hello world'
  compressed = coder.compress(sample)
  puts "Original: #{sample}"
  puts "Compressed bits: #{compressed}"
  puts "Decompressed: #{coder.decompress(compressed)}"
end
