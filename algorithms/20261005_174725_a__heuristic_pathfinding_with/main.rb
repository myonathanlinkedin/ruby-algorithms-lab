require_relative 'core'
require 'minitest/autorun'
require 'benchmark'

class TestAStar < Minitest::Test
  def setup
    # Simple 5x5 grid, 1 = free, Float::INFINITY = wall
    @costs = [
      [1, 1, 1, 1, 1],
      [1, Float::INFINITY, Float::INFINITY, Float::INFINITY, 1],
      [1, 1, 1, Float::INFINITY, 1],
      [1, Float::INFINITY, 1, 1, 1],
      [1, 1, 1, 1, 1]
    ]
    @grid = Pathfinding::Grid.new(@costs)
    @astar = Pathfinding::AStar.new(@grid)
  end

  def test_simple_path
    start = [0, 0]
    goal  = [4, 4]
    path = @astar.find_path(start, goal)
    assert path, 'Path should exist'
    assert_equal goal, path.last
    # Expected length is 9 steps (including start)
    assert_equal 9, path.size
  end

  def test_no_path
    # Block the middle column completely
    blocked_costs = @costs.map.with_index do |row, y|
      row.map.with_index { |c, x| x == 2 ? Float::INFINITY : c }
    end
    grid = Pathfinding::Grid.new(blocked_costs)
    astar = Pathfinding::AStar.new(grid)
    start = [0, 0]
    goal  = [4, 4]
    path = astar.find_path(start, goal)
    assert_nil path, 'Path should be nil when blocked'
  end

  def test_dynamic_obstacle
    # Dynamic cost: cell (2,2) becomes expensive after time 3
    dyn = proc do |x, y, t|
      (x == 2 && y == 2 && t > 3) ? 10 : 0
    end
    grid = Pathfinding::Grid.new(@costs, dyn)
    astar = Pathfinding::AStar.new(grid)
    start = [0, 0]
    goal  = [4, 4]
    path = astar.find_path(start, goal)
    assert path, 'Path should exist despite dynamic cost'
    # Ensure the algorithm prefers alternative route if time >3
    # The path should not include (2,2) when it would be visited after time 3
    index = path.index([2, 2])
    if index
      arrival_time = index # start at time 0, each step +1
      assert arrival_time <= 3, 'Dynamic cost should be avoided after time 3'
    end
  end
end

# Simple benchmark comparing static vs dynamic cost handling
if __FILE__ == $0
  puts 'Running benchmark...'
  static_grid = Pathfinding::Grid.new(Array.new(50) { Array.new(50, 1) })
  dynamic_grid = Pathfinding::Grid.new(
    Array.new(50) { Array.new(50, 1) },
    proc { |x, y, t| (x == 25 && y == 25 && t % 5 == 0) ? 5 : 0 }
  )
  static_astar = Pathfinding::AStar.new(static_grid)
  dynamic_astar = Pathfinding::AStar.new(dynamic_grid)

  Benchmark.bm(12) do |bm|
    bm.report('static') { static_astar.find_path([0, 0], [49, 49]) }
    bm.report('dynamic') { dynamic_astar.find_path([0, 0], [49, 49]) }
  end

  # Demonstration execution
  demo_grid = Pathfinding::Grid.new(@costs)
  demo_astar = Pathfinding::AStar.new(demo_grid)
  demo_path = demo_astar.find_path([0, 0], [4, 4])
  puts "Demo path: #{demo_path.inspect}"
end
