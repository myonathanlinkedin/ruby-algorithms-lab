# Domain models for the MDS recovery problem

# Observation represents a known (possibly noisy) distance between two points.
Observation = Struct.new(:i, :j, :distance) do
  def validate!(n_points)
    raise ArgumentError, "Index i out of bounds" unless i.between?(0, n_points - 1)
    raise ArgumentError, "Index j out of bounds" unless j.between?(0, n_points - 1)
    raise ArgumentError, "Distance must be non‑negative" unless distance >= 0.0
  end
end

# Config holds algorithmic hyper‑parameters.
class Config
  attr_accessor :dim, :max_iter, :learning_rate, :tolerance, :verbose

  def initialize(dim: 2, max_iter: 5000, learning_rate: 0.01, tolerance: 1e-6, verbose: false)
    @dim = dim
    @max_iter = max_iter
    @learning_rate = learning_rate
    @tolerance = tolerance
    @verbose = verbose
  end
end

# Simple assertion helper (used in tests)
def assert(condition, message = "Assertion failed")
  raise message unless condition
end
