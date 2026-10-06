# frozen_string_literal: true

# Simple immutable data holder for a cost matrix used in optimal transport.
class CostMatrix
  attr_reader :matrix, :size

  # matrix must be a square 2‑D Array of Numeric values.
  def initialize(matrix)
    raise ArgumentError, 'Cost matrix must be a non‑empty Array' unless matrix.is_a?(Array) && !matrix.empty?
    n = matrix.size
    unless matrix.all? { |row| row.is_a?(Array) && row.size == n && row.all? { |e| e.is_a?(Numeric) } }
      raise ArgumentError, 'Cost matrix must be square and contain only Numeric values'
    end
    @matrix = matrix.map { |row| row.map(&:to_f) } # ensure Float for arithmetic
    @size = n
  end
end

# Immutable result of the optimal transport computation.
TransportResult = Struct.new(:assignment, :total_cost) do
  # assignment: Array where assignment[i] = j means source i matched to target j.
  # total_cost: Numeric total transport cost.
  def validate!
    raise ArgumentError, 'Assignment must be an Array' unless assignment.is_a?(Array)
    raise ArgumentError, 'Assignment size mismatch' unless assignment.size == assignment.uniq.size
    raise ArgumentError, 'Total cost must be Numeric' unless total_cost.is_a?(Numeric)
    self
  end
end
