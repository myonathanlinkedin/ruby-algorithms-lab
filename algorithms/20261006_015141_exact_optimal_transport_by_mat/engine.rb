# frozen_string_literal: true

require_relative 'types'

# Core implementation of the Hungarian (Kuhn‑Munkres) algorithm for exact
# optimal transport when source and target masses are unitary.
class HungarianSolver
  # Solves the assignment problem for a given CostMatrix.
  # Returns a TransportResult with the optimal assignment and its total cost.
  def solve(cost_matrix)
    cost = cost_matrix.matrix
    n = cost_matrix.size
    # Implementation follows the classic O(n³) algorithm using potentials.
    u = Array.new(n + 1, 0.0)
    v = Array.new(n + 1, 0.0)
    p = Array.new(n + 1, 0)
    way = Array.new(n + 1, 0)

    (1..n).each do |i|
      p[0] = i
      j0 = 0
      minv = Array.new(n + 1, Float::INFINITY)
      used = Array.new(n + 1, false)

      loop do
        used[j0] = true
        i0 = p[j0]
        delta = Float::INFINITY
        j1 = nil

        (1..n).each do |j|
          next if used[j]

          cur = cost[i0 - 1][j - 1] - u[i0] - v[j]
          if cur < minv[j]
            minv[j] = cur
            way[j] = j0
          end
          if minv[j] < delta
            delta = minv[j]
            j1 = j
          end
        end

        (0..n).each do |j|
          if used[j]
            u[p[j]] += delta
            v[j] -= delta
          else
            minv[j] -= delta
          end
        end

        j0 = j1
        break if p[j0].zero?
      end

      # Augmenting path reconstruction
      loop do
        j1 = way[j0]
        p[j0] = p[j1]
        j0 = j1
        break if j0.zero?
      end
    end

    assignment = Array.new(n)
    (1..n).each do |j|
      assignment[p[j] - 1] = j - 1
    end

    total_cost = 0.0
    assignment.each_with_index { |col, row| total_cost += cost[row][col] }

    TransportResult.new(assignment, total_cost).validate!
  end
end
