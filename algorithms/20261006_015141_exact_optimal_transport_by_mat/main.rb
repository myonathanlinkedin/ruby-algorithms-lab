# frozen_string_literal: true

require_relative 'types'
require_relative 'engine'

# Simple assertion helper
def assert(condition, message = 'Assertion failed')
  raise RuntimeError, message unless condition
end

def test_known_matrix
  # Example from classic assignment problem literature.
  matrix = [
    [90, 75, 75, 80],
    [35, 85, 55, 65],
    [125, 95, 90, 105],
    [45, 110, 95, 115]
  ]
  cm = CostMatrix.new(matrix)
  solver = HungarianSolver.new
  result = solver.solve(cm)

  expected_assignment = [1, 0, 2, 3] # rows -> columns (0‑based)
  expected_cost = 275.0

  assert(result.assignment == expected_assignment, "Expected assignment #{expected_assignment}, got #{result.assignment}")
  assert((result.total_cost - expected_cost).abs < 1e-6, "Expected cost #{expected_cost}, got #{result.total_cost}")
end

def test_zero_matrix
  n = 5
  matrix = Array.new(n) { Array.new(n, 0) }
  cm = CostMatrix.new(matrix)
  solver = HungarianSolver.new
  result = solver.solve(cm)

  assert(result.total_cost.zero?, 'Total cost should be zero for zero matrix')
  assert(result.assignment.sort == (0...n).to_a, 'Assignment must be a permutation')
end

def test_random_small_bruteforce
  require 'set'

  n = 4
  rng = Random.new(42)
  matrix = Array.new(n) { Array.new(n) { rng.rand(0..20) } }
  cm = CostMatrix.new(matrix)
  solver = HungarianSolver.new
  result = solver.solve(cm)

  # Brute‑force check all permutations
  best_cost = Float::INFINITY
  best_perm = nil
  (0...n).to_a.permutation.each do |perm|
    cost = 0
    perm.each_with_index { |col, row| cost += matrix[row][col] }
    if cost < best_cost
      best_cost = cost
      best_perm = perm.dup
    end
  end

  assert((result.total_cost - best_cost).abs < 1e-6, "Brute‑force cost #{best_cost}, solver gave #{result.total_cost}")
  assert(result.assignment == best_perm, "Brute‑force assignment #{best_perm}, solver gave #{result.assignment}")
end

def demo
  puts '--- Exact Optimal Transport via Hungarian Matching Demo ---'
  matrix = [
    [4, 1, 3],
    [2, 0, 5],
    [3, 2, 2]
  ]
  cm = CostMatrix.new(matrix)
  solver = HungarianSolver.new
  result = solver.solve(cm)
  puts "Cost matrix:"
  matrix.each { |row| puts row.map { |v| format('%4.1f', v) }.join }
  puts "\nOptimal assignment (source -> target):"
  result.assignment.each_with_index { |col, row| puts "  #{row} -> #{col}" }
  puts "Total minimal transport cost: #{result.total_cost}"
end

# Execute tests
test_known_matrix
test_zero_matrix
test_random_small_bruteforce

# Run demonstration
demo

puts "\nAll tests passed successfully."
