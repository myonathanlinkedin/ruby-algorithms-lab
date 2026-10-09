require_relative 'engine'

# Helper to generate synthetic data
def generate_random_points(n, dim)
  Array.new(n) { Array.new(dim) { rand(-10.0..10.0) } }
end

def euclidean_distance(p, q)
  Math.sqrt(p.zip(q).reduce(0.0) { |sum, (a, b)| sum + (a - b) ** 2 })
end

def all_pairwise_observations(points)
  obs = []
  n = points.size
  (0...n).each do |i|
    ((i + 1)...n).each do |j|
      d = euclidean_distance(points[i], points[j])
      obs << Observation.new(i, j, d)
    end
  end
  obs
end

def drop_random_observations(observations, drop_fraction)
  total = observations.size
  keep = (total * (1.0 - drop_fraction)).ceil
  observations.shuffle.take(keep)
end

# Unit test driver
def run_tests
  dim = 2
  n_points = 6
  original = generate_random_points(n_points, dim)

  # Full distance observations
  full_obs = all_pairwise_observations(original)

  # Sparse observations (drop 40%)
  sparse_obs = drop_random_observations(full_obs, 0.4)

  cfg = Config.new(dim: dim, max_iter: 3000, learning_rate: 0.02, tolerance: 1e-8, verbose: false)
  recoverer = MDSRecover.new(sparse_obs, n_points, cfg)
  recovered = recoverer.recover

  # Evaluate reconstruction error on the *observed* distances
  total_error = 0.0
  sparse_obs.each do |o|
    i, j, d_true = o.i, o.j, o.distance
    d_rec = euclidean_distance(recovered[i], recovered[j])
    total_error += (d_rec - d_true).abs
  end
  mae = total_error / sparse_obs.size

  puts "Mean absolute distance error on observed pairs: #{mae.round(6)}"

  # The algorithm is stochastic; we accept a modest error.
  assert(mae < 0.2, "Reconstruction error too high (MAE=#{mae})")
  puts "All assertions passed."
end

run_tests
