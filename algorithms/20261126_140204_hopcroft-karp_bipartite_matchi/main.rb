require_relative 'types'
require_relative 'engine'

def assert(condition, message = 'Assertion failed')
  raise message unless condition
end

def test_empty_graph
  g = BipartiteGraph.new
  hk = HopcroftKarp.new(g)
  assert(hk.max_matching == 0, 'Empty graph should have 0 matching')
  assert(hk.matching_pairs.empty?, 'No pairs in empty graph')
end

def test_single_edge
  g = BipartiteGraph.new
  g.add_edge(1, 'a')
  hk = HopcroftKarp.new(g)
  assert(hk.max_matching == 1, 'Single edge matching size 1')
  assert(hk.matching_pairs == [[1, 'a']], 'Matching pair incorrect')
end

def test_no_matching
  g = BipartiteGraph.new
  g.add_left(1)
  g.add_left(2)
  g.add_right('a')
  hk = HopcroftKarp.new(g)
  assert(hk.max_matching == 0, 'No edges should yield 0 matching')
end

def test_full_bipartite
  g = BipartiteGraph.new
  left = [1, 2, 3]
  right = ['a', 'b', 'c']
  left.each { |u| g.add_left(u) }
  right.each { |v| g.add_right(v) }
  left.each do |u|
    right.each { |v| g.add_edge(u, v) }
  end
  hk = HopcroftKarp.new(g)
  assert(hk.max_matching == 3, 'Full bipartite should match min(|L|,|R|)')
  pairs = hk.matching_pairs
  assert(pairs.size == 3, 'Matching size 3')
  left.each { |u| assert(pairs.any? { |p| p[0] == u }, "Left node #{u} matched") }
  right.each { |v| assert(pairs.any? { |p| p[1] == v }, "Right node #{v} matched") }
end

def test_complex
  g = BipartiteGraph.new
  g.add_edge(1, 'a')
  g.add_edge(1, 'b')
  g.add_edge(2, 'b')
  g.add_edge(2, 'c')
  g.add_edge(3, 'c')
  g.add_edge(3, 'd')
  hk = HopcroftKarp.new(g)
  assert(hk.max_matching == 3, 'Complex graph matching size 3')
  pairs = hk.matching_pairs
  assert(pairs.size == 3, 'Matching size 3')
  right_nodes = pairs.map { |p| p[1] }
  assert(right_nodes.uniq.size == 3, 'Right nodes unique')
end

test_empty_graph
test_single_edge
test_no_matching
test_full_bipartite
test_complex

puts 'All tests passed.'

demo_graph = BipartiteGraph.new
demo_graph.add_edge(1, 'x')
demo_graph.add_edge(1, 'y')
demo_graph.add_edge(2, 'y')
demo_graph.add_edge(2, 'z')
demo_graph.add_edge(3, 'z')
demo_graph.add_edge(3, 'w')
hk_demo = HopcroftKarp.new(demo_graph)
matching_size = hk_demo.max_matching
puts "Demo matching size: #{matching_size}"
puts "Matching pairs: #{hk_demo.matching_pairs.inspect}"
