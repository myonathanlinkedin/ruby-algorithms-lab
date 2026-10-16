class AVLTree
  Node = Struct.new(:key, :value, :height, :left, :right) do
    def initialize(key, value = nil)
      super(key, value, 1, nil, nil)
    end
  end

  attr_reader :root, :size

  def initialize
    @root = nil
    @size = 0
  end

  # Public API ----------------------------------------------------
  def insert(key, value = nil)
    @found_duplicate = false
    @root = insert_node(@root, key, value)
    @size += 1 unless @found_duplicate
    self
  end

  def delete(key)
    @root, deleted = delete_node(@root, key)
    @size -= 1 if deleted
    self
  end

  def get(key)
    node = find_node(@root, key)
    node ? node.value : nil
  end

  def inorder
    Enumerator.new do |y|
      inorder_traverse(@root) { |node| y << [node.key, node.value] }
    end.to_a
  end

  def balanced?
    check_balance(@root)
  end

  # ----------------------------------------------------------------
  private

  # Insert helper -------------------------------------------------
  def insert_node(node, key, value)
    return Node.new(key, value) if node.nil?

    if key < node.key
      node.left = insert_node(node.left, key, value)
    elsif key > node.key
      node.right = insert_node(node.right, key, value)
    else
      @found_duplicate = true
      node.value = value
      return node
    end

    update_height(node)
    rebalance(node)
  end

  # Delete helper -------------------------------------------------
  def delete_node(node, key)
    return [nil, false] if node.nil?

    deleted = false
    if key < node.key
      node.left, deleted = delete_node(node.left, key)
    elsif key > node.key
      node.right, deleted = delete_node(node.right, key)
    else
      deleted = true
      if node.left && node.right
        succ = min_node(node.right)
        node.key, node.value = succ.key, succ.value
        node.right, _ = delete_node(node.right, succ.key)
      elsif node.left
        return [node.left, true]
      elsif node.right
        return [node.right, true]
      else
        return [nil, true]
      end
    end

    update_height(node)
    [rebalance(node), deleted]
  end

  # Search ---------------------------------------------------------
  def find_node(node, key)
    while node
      return node if key == node.key
      node = key < node.key ? node.left : node.right
    end
    nil
  end

  # Minimum node ---------------------------------------------------
  def min_node(node)
    node = node.left while node.left
    node
  end

  # Traversal ------------------------------------------------------
  def inorder_traverse(node, &block)
    return unless node
    inorder_traverse(node.left, &block)
    yield node
    inorder_traverse(node.right, &block)
  end

  # Height utilities -----------------------------------------------
  def height(node)
    node ? node.height : 0
  end

  def update_height(node)
    node.height = 1 + [height(node.left), height(node.right)].max
  end

  def balance_factor(node)
    height(node.left) - height(node.right)
  end

  # Rotations ------------------------------------------------------
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

  # Rebalance ------------------------------------------------------
  def rebalance(node)
    bf = balance_factor(node)

    if bf > 1
      node.left = rotate_left(node.left) if balance_factor(node.left) < 0
      return rotate_right(node)
    elsif bf < -1
      node.right = rotate_right(node.right) if balance_factor(node.right) > 0
      return rotate_left(node)
    end
    node
  end

  # Balance verification -------------------------------------------
  def check_balance(node)
    return true if node.nil?
    bf = balance_factor(node)
    return false if bf.abs > 1
    check_balance(node.left) && check_balance(node.right)
  end
end
