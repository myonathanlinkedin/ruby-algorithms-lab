class AVLTree
  # Node class encapsulates a tree node.
  class Node
    attr_accessor :key, :value, :height, :left, :right

    def initialize(key, value)
      @key = key
      @value = value
      @height = 1
      @left = nil
      @right = nil
    end
  end

  attr_reader :root, :size

  def initialize
    @root = nil
    @size = 0
  end

  # Public API ---------------------------------------------------------

  # Insert a key/value pair. Duplicate keys replace the existing value.
  def insert(key, value)
    @root = insert_rec(@root, key, value)
    @size += 1 unless find_node(@root, key).nil? && @size == 0
    self
  end

  # Delete a key. No-op if key absent.
  def delete(key)
    if find(key)
      @root = delete_rec(@root, key)
      @size -= 1
    end
    self
  end

  # Retrieve value for a key, or nil.
  def find(key)
    node = find_node(@root, key)
    node ? node.value : nil
  end

  # Return array of [key, value] in-order.
  def inorder
    result = []
    inorder_rec(@root, result)
    result
  end

  # Aether-Continuum: return sorted array of keys.
  def aether_continuum
    inorder.map { |kv| kv[0] }
  end

  # Merge another AVLTree into this one. Keys must be unique across trees.
  def merge(other)
    other.inorder.each { |k, v| insert(k, v) }
    self
  end

  # --------------------------------------------------------------------

  private

  # Recursive insertion with rebalancing.
  def insert_rec(node, key, value)
    return Node.new(key, value) if node.nil?

    if key < node.key
      node.left = insert_rec(node.left, key, value)
    elsif key > node.key
      node.right = insert_rec(node.right, key, value)
    else
      node.value = value
      return node
    end

    update_height(node)
    rebalance(node)
  end

  # Recursive deletion with rebalancing.
  def delete_rec(node, key)
    return nil if node.nil?

    if key < node.key
      node.left = delete_rec(node.left, key)
    elsif key > node.key
      node.right = delete_rec(node.right, key)
    else
      # Node with one or no child.
      return node.right if node.left.nil?
      return node.left if node.right.nil?

      # Node with two children: replace with inorder successor.
      succ = min_node(node.right)
      node.key, node.value = succ.key, succ.value
      node.right = delete_rec(node.right, succ.key)
    end

    update_height(node)
    rebalance(node)
  end

  # Find node by key.
  def find_node(node, key)
    return nil if node.nil?
    return node if key == node.key
    key < node.key ? find_node(node.left, key) : find_node(node.right, key)
  end

  # In-order traversal helper.
  def inorder_rec(node, arr)
    return if node.nil?
    inorder_rec(node.left, arr)
    arr << [node.key, node.value]
    inorder_rec(node.right, arr)
  end

  # Height utilities.
  def height(node)
    node ? node.height : 0
  end

  def update_height(node)
    node.height = 1 + [height(node.left), height(node.right)].max
  end

  def balance_factor(node)
    height(node.left) - height(node.right)
  end

  # Rebalancing dispatcher.
  def rebalance(node)
    bf = balance_factor(node)

    # Left heavy
    if bf > 1
      if balance_factor(node.left) < 0
        node.left = rotate_left(node.left)
      end
      return rotate_right(node)
    end

    # Right heavy
    if bf < -1
      if balance_factor(node.right) > 0
        node.right = rotate_right(node.right)
      end
      return rotate_left(node)
    end

    node
  end

  # Rotations.
  def rotate_right(y)
    x = y.left
    t2 = x.right
    x.right = y
    y.left = t2
    update_height(y)
    update_height(x)
    x
  end

  def rotate_left(x)
    y = x.right
    t2 = y.left
    y.left = x
    x.right = t2
    update_height(x)
    update_height(y)
    y
  end

  # Minimum node in subtree.
  def min_node(node)
    current = node
    current = current.left while current.left
    current
  end
end
