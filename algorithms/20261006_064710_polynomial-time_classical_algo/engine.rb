require_relative 'types'

class MeanFieldSolver
  DEFAULT_TOLERANCE = 1e-8
  DEFAULT_MAX_ITER = 10_000

  def initialize(tolerance: DEFAULT_TOLERANCE, max_iter: DEFAULT_MAX_ITER)
    @tolerance = tolerance
    @max_iter = max_iter
  end

  # Returns array of magnetizations m_i
  def solve(model)
    n = model.size
    m = Array.new(n, 0.0) # start from zero magnetization
    beta = 1.0 / model.temperature

    @max_iter.times do
      m_new = Array.new(n) do |i|
        local_field = model.field[i] + sum_couplings(model.interaction, m, i)
        Math.tanh(beta * local_field)
      end

      diff = max_abs_diff(m, m_new)
      m = m_new
      break if diff < @tolerance
    end

    m
  end

  private

  def sum_couplings(interaction, mags, i)
    sum = 0.0
    mags.each_with_index { |mj, j| sum += interaction[i, j] * mj }
    sum
  end

  def max_abs_diff(a, b)
    a.zip(b).map { |x, y| (x - y).abs }.max
  end
end
