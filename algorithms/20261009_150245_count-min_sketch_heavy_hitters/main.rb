# frozen_string_literal: true

require_relative 'engine'

# Minimal assertion helper (raises on failure)
def assert(condition, message = 'Assertion failed')
  raise message unless condition
end

# Helper to compare two hashes for equality irrespective of order
def hash_counts_equal?(a, b)
  a.all? { |k, v| b[k] == v } && b.all? { |k, v| a[k] == v }
end

# ------------------------------
# Unit Tests
# ------------------------------

# Test 1: Basic update / estimate correctness
config = SketchConfig.new(1000, 5)
cms = CountMinSketch.new(config)

# Stream of items with known frequencies
stream = %w[apple banana apple orange banana apple grape]
true_counts = Hash.new(0)
stream.each { |item| true_counts[item] += 1; cms.update(item) }

# Verify that estimate is never less than true count (property of CMS)
true_counts.each do |item, true_cnt|
  est = cms.estimate(item)
  assert(est >= true_cnt, "Estimate #{est} < true count #{true_cnt} for #{item}")
end

# Verify that an unseen item yields zero estimate
assert(cms.estimate('pineapple') == 0, 'Unseen item should have zero estimate')

# Test 2: Heavy‑hitter extraction
threshold = 2
hh = cms.heavy_hitters(threshold)
hh_items = hh.map(&:item)
expected_hh = true_counts.select { |_k, v| v >= threshold }.keys
assert(hash_counts_equal?(hh_items.map { |i| [i, true] }.to_h,
                          expected_hh.map { |i| [i, true] }.to_h),
       "Heavy hitters mismatch. Expected #{expected_hh}, got #{hh_items}")

# Test 3: Edge cases – large delta and repeated updates
cms2 = CountMinSketch.new(SketchConfig.new(50, 3))
cms2.update('x', 10)
cms2.update('x', 5)
assert(cms2.estimate('x') >= 15, 'Large delta updates failed')
assert(cms2.estimate('y') == 0, 'Zero estimate for never‑seen item failed')

# Test 4: Invalid configuration handling
begin
  CountMinSketch.new(SketchConfig.new(0, 5))
  raise 'Zero width should have raised'
rescue ArgumentError
  # Expected
end

begin
  CountMinSketch.new(SketchConfig.new(10, -1))
  raise 'Negative depth should have raised'
rescue ArgumentError
  # Expected
end

# Test 5: Invalid update arguments
begin
  cms.update('z', -3)
  raise 'Negative delta should have raised'
rescue ArgumentError
  # Expected
end

# ------------------------------
# Demo Execution (optional)
# ------------------------------
if __FILE__ == $PROGRAM_NAME
  puts 'All unit tests passed.'

  demo = CountMinSketch.new(SketchConfig.new(200, 4))
  %w[alpha beta gamma alpha beta alpha delta epsilon beta].each { |it| demo.update(it) }

  puts "\nEstimated frequencies:"
  %w[alpha beta gamma delta epsilon].each do |it|
    puts "#{it.ljust(7)} => #{demo.estimate(it)}"
  end

  puts "\nHeavy hitters (threshold >= 2):"
  demo.heavy_hitters(2).each { |hh| puts hh }
end
