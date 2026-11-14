class AVLNode
  attr_accessor :key, :value, :height, :left, :right, :parent

  def initialize(key, value = nil, parent = nil)
    @key = key
    @value = value
    @height = 1
    @left = nil
    @right = nil
    @parent = parent
  end
end

class AVLTree
  attr_reader :root

  def initialize
    @root = nil
  end

  # Public API ----------------------------------------------------
  def insert(key, value = nil)
    @root = insert_rec(@root, key, value, nil)
  end

  def delete(key)
    @root = delete_rec(@root, key)
  end

  def find(key)
    node = @root
    while node
      if key < node.key
        node = node.left
      elsif key > node.key
        node = node.right
      else
        return node
      end
    end
    nil
  end

  def inorder
    result = []
    inorder_rec(@root, result)
    result
  end

  # Returns array of [parent_key, child_key] for each edge.
  def graph_edges
    edges = []
    traverse_edges(@root, edges)
    edges
  end

  # ----------------------------------------------------------------
  private

  def height(node)
    node ? node.height : 0
  end

  def update_height(node)
    node.height = 1 + [height(node.left), height(node.right)].max
  end

  def balance_factor(node)
    height(node.left) - height(node.right)
  end

  # Rotations -------------------------------------------------------
  def rotate_right(y)
    x = y.left
    t2 = x.right

    # Rotation
    x.right = y
    y.left = t2

    # Update parents
    x.parent = y.parent
    y.parent = x
    t2.parent = y if t2

    # Update heights
    update_height(y)
    update_height(x)

    x
  end

  def rotate_left(x)
    y = x.right
    t2 = y.left

    # Rotation
    y.left = x
    x.right = t2

    # Update parents
    y.parent = x.parent
    x.parent = y
    t2.parent = x if t2

    # Update heights
    update_height(x)
    update_height(y)

    y
  end

  def rebalance(node)
    update_height(node)
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

  # Insertion -------------------------------------------------------
  def insert_rec(node, key, value, parent)
    return AVLNode.new(key, value, parent) unless node

    if key < node.key
      node.left = insert_rec(node.left, key, value, node)
    elsif key > node.key
      node.right = insert_rec(node.right, key, value, node)
    else
      node.value = value
      return node
    end

    rebalance(node)
  end

  # Deletion --------------------------------------------------------
  def delete_rec(node, key)
    return nil unless node

    if key < node.key
      node.left = delete_rec(node.left, key)
    elsif key > node.key
      node.right = delete_rec(node.right, key)
    else
      # Node with one child or no child
      if node.left.nil?
        temp = node.right
        temp.parent = node.parent if temp
        return temp
      elsif node.right.nil?
        temp = node.left
        temp.parent = node.parent if temp
        return temp
      else
        # Node with two children: get inorder successor
        succ = min_value_node(node.right)
        node.key = succ.key
        node.value = succ.value
        node.right = delete_rec(node.right, succ.key)
      end
    end

    rebalance(node)
  end

  def min_value_node(node)
    current = node
    current = current.left while current.left
    current
  end

  # Traversals ------------------------------------------------------
  def inorder_rec(node, arr)
    return unless node
    inorder_rec(node.left, arr)
    arr << node.key
    inorder_rec(node.right, arr)
  end

  def traverse_edges(node, edges)
    return unless node
    if node.left
      edges << [node.key, node.left.key]
      traverse_edges(node.left, edges)
    end
    if node.right
      edges << [node.key, node.right.key]
      traverse_edges(node.right, edges)
    end
  end
end
