class GraphError < StandardError; end

class Node
  attr_reader :id

  def initialize(id)
    @id = id.freeze
  end

  def ==(other)
    other.is_a?(Node) && id == other.id
  end

  alias eql? ==

  def hash
    id.hash
  end

  def to_s
    "Node(#{id})"
  end
end
end
