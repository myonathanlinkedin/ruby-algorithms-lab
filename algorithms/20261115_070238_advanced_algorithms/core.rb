# frozen_string_literal: true

# Fibonacci Heap implementation for priority queue operations.
class FibonacciHeap
  class Node
    attr_accessor :key, :value, :degree, :parent, :child, :left, :right, :mark

    def initialize(key, value = nil)
      @key = key
      @value = value
      @degree = 0
      @parent = nil
      @child = nil
      @left = self
      @right = self
      @mark = false
    end
  end

  attr_reader :min, :size

  def initialize
    @min = nil
    @size = 0
  end

  def empty?
    @min.nil?
  end

  def insert(key, value = nil)
    node = Node.new(key, value)
    @min = merge_lists(@min, node)
    @size += 1
    node
  end

  def find_min
    @min
  end

  def extract_min
    z = @min
    return nil if z.nil?

    # add children of z to root list
    if z.child
      children = []
      x = z.child
      loop do
        children << x
        x = x.right
        break if x == z.child
      end
      children.each { |x| @min = merge_lists(@min, x) }
    end

    # remove z from root list
    remove_from_root_list(z)
    @size -= 1
    if @size.zero?
      @min = nil
    else
      @min = z.right
      consolidate
    end
    z
  end

  def decrease_key(node, new_key)
    raise ArgumentError, 'new key is greater than current key' if new_key > node.key

    node.key = new_key
    y = node.parent
    if y && node.key < y.key
      cut(node, y)
      cascading_cut(y)
    end
    @min = node if node.key < @min.key
    node
  end

  private

  def merge_lists(a, b)
    return a if b.nil?
    return b if a.nil?

    a_right = a.right
    b_left = b.left

    a.right = b
    b.left = a
    a_right.left = b_left
    b_left.right = a_right

    a.key < b.key ? a : b
  end

  def remove_from_root_list(node)
    if node.right == node
      @min = nil
    else
      node.left.right = node.right
      node.right.left = node.left
      @min = node.right if @min == node
    end
    node.left = node.right = node
  end

  def consolidate
    max_degree = ((Math.log2(@size)).ceil) + 1
    a = Array.new(max_degree, nil)

    roots = []
    x = @min
    loop do
      roots << x
      x = x.right
      break if x == @min
    end

    roots.each do |w|
      x = w
      d = x.degree
      while a[d]
        y = a[d]
        if x.key > y.key
          x, y = y, x
        end
        link(y, x)
        a[d] = nil
        d += 1
      end
      a[d] = x
    end

    @min = nil
    a.compact.each { |node| @min = merge_lists(@min, node) }
  end

  def link(y, x)
    # remove y from root list
    y.left.right = y.right
    y.right.left = y.left
    # make y a child of x
    y.parent = x
    y.mark = false
    if x.child
      y.left = x.child
      y.right = x.child.right
      x.child.right.left = y
      x.child.right = y
    else
      x.child = y
      y.left = y.right = y
    end
    x.degree += 1
  end

  def cut(x, y)
    # remove x from child list of y
    if x.right == x
      y.child = nil
    else
      x.right.left = x.left
      x.left.right = x.right
      y.child = x.right if y.child == x
    end
    y.degree -= 1
    # add x to root list
    x.left = x.right = x
    @min = merge_lists(@min, x)
    x.parent = nil
    x.mark = false
  end

  def cascading_cut(y)
    z = y.parent
    return unless z

    if !y.mark
      y.mark = true
    else
      cut(y, z)
      cascading_cut(z)
    end
  end
end

# Simple weighted directed graph.
class Graph
  Edge = Struct.new(:to, :weight)

  def initialize
    @adj = Hash.new { |h, k| h[k] = [] }
  end

  def add_vertex(v)
    @adj[v] = [] unless @adj.key?(v)
    self
  end

  def add_edge(from, to, weight)
    raise ArgumentError, 'weight must be non‑negative' if weight < 0

    add_vertex(from)
    add_vertex(to)
    @adj[from] << Edge.new(to, weight)
    self
  end

  def vertices
    @adj.keys
  end

  def neighbors(v)
    @adj[v]
  end

  # Dijkstra's algorithm using Fibonacci heap.
  # Returns a hash: distance[v] = shortest distance from source to v (Float::INFINITY if unreachable)
  # and a hash: previous[v] = predecessor of v on the shortest path (nil for source or unreachable)
  def dijkstra(source)
    raise ArgumentError, 'source vertex not in graph' unless @adj.key?(source)

    dist = {}
    prev = {}
    heap = FibonacciHeap.new
    node_map = {}

    @adj.each_key do |v|
      if v == source
        dist[v] = 0
        node_map[v] = heap.insert(0, v)
      else
        dist[v] = Float::INFINITY
        node_map[v] = heap.insert(Float::INFINITY, v)
      end
      prev[v] = nil
    end

    until heap.empty?
      u_node = heap.extract_min
      u = u_node.value
      break if u_node.key == Float::INFINITY

      @adj[u].each do |edge|
        alt = dist[u] + edge.weight
        if alt < dist[edge.to]
          dist[edge.to] = alt
          prev[edge.to] = u
          heap.decrease_key(node_map[edge.to], alt)
        end
      end
    end

    [dist, prev]
  end
end
