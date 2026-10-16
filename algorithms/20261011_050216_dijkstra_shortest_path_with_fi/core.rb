# Dijkstra's algorithm with a Fibonacci Heap priority queue.
# Pure Ruby implementation using only the standard library.

# ---------- Fibonacci Heap ----------
class FibNode
  attr_accessor :key, :value, :degree, :parent, :child, :mark, :left, :right

  def initialize(key, value = nil)
    @key   = key
    @value = value
    @degree = 0
    @parent = nil
    @child  = nil
    @mark   = false
    @left   = self
    @right  = self
  end

  # Insert node into circular doubly linked list after self.
  def insert_after(node)
    node.right = @right
    node.left  = self
    @right.left = node
    @right = node
  end

  # Remove self from its circular list.
  def remove_from_list
    @left.right = @right
    @right.left = @left
    @left = @right = self
  end

  # Iterate over the list starting from self.
  def each
    node = self
    loop do
      yield node
      node = node.right
      break if node == self
    end
  end
end

class FibonacciHeap
  attr_reader :min, :size

  def initialize
    @min  = nil
    @size = 0
  end

  # Insert a new key/value pair. Returns the created node.
  def insert(key, value = nil)
    node = FibNode.new(key, value)
    if @min
      @min.insert_after(node)
      @min = node if node.key < @min.key
    else
      @min = node
    end
    @size += 1
    node
  end

  # Return the minimum key without removing it.
  def peek_min
    @min
  end

  # Extract the node with minimum key.
  def extract_min
    z = @min
    return nil unless z

    # Add children of z to root list.
    if z.child
      children = []
      z.child.each { |c| children << c }
      children.each do |c|
        c.parent = nil
        @min.insert_after(c)
      end
    end

    # Remove z from root list.
    if z == z.right
      @min = nil
    else
      z.remove_from_list
      @min = z.right
      consolidate
    end
    @size -= 1
    z
  end

  # Decrease the key of a given node.
  def decrease_key(node, new_key)
    raise ArgumentError, 'new key is greater than current key' if new_key > node.key
    node.key = new_key
    y = node.parent
    if y && node.key < y.key
      cut(node, y)
      cascading_cut(y)
    end
    @min = node if node.key < @min.key
    self
  end

  private

  # Link node y under node x (both roots of same degree).
  def link(y, x)
    y.remove_from_list
    if x.child
      x.child.insert_after(y)
    else
      x.child = y
    end
    y.parent = x
    x.degree += 1
    y.mark = false
  end

  # Consolidate trees in the root list so that at most one tree of each degree exists.
  def consolidate
    max_degree = (@size.to_f.log2).ceil + 1
    aux = Array.new(max_degree, nil)

    roots = []
    @min.each { |r| roots << r }

    roots.each do |w|
      x = w
      d = x.degree
      while aux[d]
        y = aux[d]
        if x.key > y.key
          x, y = y, x
        end
        link(y, x)
        aux[d] = nil
        d += 1
      end
      aux[d] = x
    end

    @min = nil
    aux.compact.each do |node|
      if @min
        @min.insert_after(node)
        @min = node if node.key < @min.key
      else
        @min = node
      end
    end
  end

  def cut(x, y)
    # Remove x from child list of y.
    if y.child == x
      if x.right != x
        y.child = x.right
      else
        y.child = nil
      end
    end
    x.remove_from_list
    y.degree -= 1
    # Add x to root list.
    @min.insert_after(x)
    x.parent = nil
    x.mark = false
  end

  def cascading_cut(y)
    z = y.parent
    if z
      if !y.mark
        y.mark = true
      else
        cut(y, z)
        cascading_cut(z)
      end
    end
  end
end

# ---------- Graph ----------
class Graph
  Edge = Struct.new(:to, :weight)

  def initialize
    @adj = Hash.new { |h, k| h[k] = [] }
  end

  # Add a directed edge u -> v with non‑negative weight.
  def add_edge(u, v, weight)
    raise ArgumentError, 'weight must be non‑negative' if weight < 0
    @adj[u] << Edge.new(v, weight)
    @adj[v] ||= [] # ensure v appears in adjacency hash
    self
  end

  # Dijkstra's algorithm from source vertex.
  # Returns a hash of distances and a hash of predecessors.
  def dijkstra(source)
    dist = {}
    prev = {}
    heap = FibonacciHeap.new
    node_refs = {}

    @adj.keys.each do |v|
      if v == source
        dist[v] = 0
        node_refs[v] = heap.insert(0, v)
      else
        dist[v] = Float::INFINITY
        node_refs[v] = heap.insert(Float::INFINITY, v)
      end
      prev[v] = nil
    end

    until heap.size.zero?
      u_node = heap.extract_min
      u = u_node.value
      break if dist[u] == Float::INFINITY # remaining vertices unreachable

      @adj[u].each do |edge|
        alt = dist[u] + edge.weight
        if alt < dist[edge.to]
          dist[edge.to] = alt
          prev[edge.to] = u
          heap.decrease_key(node_refs[edge.to], alt)
        end
      end
    end

    [dist, prev]
  end
end

# === END OF core.rb ===
