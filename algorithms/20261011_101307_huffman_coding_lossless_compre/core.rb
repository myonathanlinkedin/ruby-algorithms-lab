class HuffmanNode
  attr_accessor :freq, :char, :left, :right

  def initialize(freq:, char: nil, left: nil, right: nil)
    @freq = freq
    @char = char
    @left = left
    @right = right
  end

  def leaf?
    @left.nil? && @right.nil?
  end
end

class HuffmanCoder
  def initialize
    @root = nil
    @codes = {}
  end

  def compress(text)
    return '' if text.empty?
    freq = frequency_map(text)
    @root = build_tree(freq)
    @codes = generate_codes(@root)
    return '' if @root.leaf?
    encode(text, @codes)
  end

  def decompress(bitstring)
    return '' if @root.nil?
    return @root.char * @root.freq if @root.leaf?
    return '' if bitstring.empty?
    decode(bitstring, @root)
  end

  private

  def frequency_map(text)
    freq = Hash.new(0)
    text.each_char { |c| freq[c] += 1 }
    freq
  end

  def build_tree(freq)
    nodes = freq.map { |char, f| HuffmanNode.new(freq: f, char: char) }
    while nodes.size > 1
      nodes.sort_by!(&:freq)
      left = nodes.shift
      right = nodes.shift
      parent = HuffmanNode.new(freq: left.freq + right.freq, left: left, right: right)
      nodes << parent
    end
    nodes.first
  end

  def generate_codes(node, prefix = '', codes = {})
    if node.leaf?
      codes[node.char] = prefix.empty? ? '0' : prefix
    else
      generate_codes(node.left, prefix + '0', codes) if node.left
      generate_codes(node.right, prefix + '1', codes) if node.right
    end
    codes
  end

  def encode(text, codes)
    text.chars.map { |c| codes[c] }.join
  end

  def decode(bitstring, node)
    result = +''
    current = node
    bitstring.each_char do |bit|
      current = bit == '0' ? current.left : current.right
      if current.leaf?
        result << current.char
        current = node
      end
    end
    result
  end
end
