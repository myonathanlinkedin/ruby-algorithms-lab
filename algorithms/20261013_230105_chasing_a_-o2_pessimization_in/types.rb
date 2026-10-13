# frozen_string_literal: true

# Disjoint set element representation.
# Stores parent reference and rank for union by rank heuristic.
class DisjointSetElement
  attr_accessor :parent, :rank, :value

  # Initialize a new element. Initially, it is its own parent.
  #
  # @param value [Object] the payload stored in the element (e.g., an identifier)
  def initialize(value)
    @value = value
    @parent = self
    @rank = 0
  end
end
