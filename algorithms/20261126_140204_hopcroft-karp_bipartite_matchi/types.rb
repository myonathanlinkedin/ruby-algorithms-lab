class BipartiteGraph
  attr_reader :left_nodes, :right_nodes, :adjacency

  def initialize
    @left_nodes = []
    @right_nodes = []
    @adjacency = Hash.new { |h, k| h[k] = [] }
  end

  def add_left(node)
    @left_nodes << node unless @left_nodes.include?(node)
  end

  def add_right(node)
    @right_nodes << node unless @right_nodes.include?(node)
  end

  def add_edge(u, v)
    add_left(u)
    add_right(v)
    @adjacency[u] << v unless @adjacency[u].include?(v)
  end
end
