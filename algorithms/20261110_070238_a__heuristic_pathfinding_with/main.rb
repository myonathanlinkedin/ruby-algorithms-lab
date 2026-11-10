require 'minitest/autorun'
require_relative 'core'

class TestAStar < Minitest::Test
  def setup
    @grid = Grid.new(5, 5) # 5×5 grid, default cost 1
    @astar = AStar.new(@grid)
  end

  def test_straight_line_path
    path = @astar.find_path([0, 0], [4, 0])
    expected = [[0,0],[1,0],[2,0],[3,0],[4,0]]
    assert_equal expected, path
  end

  def test_basic_diagonal_path
    path = @astar.find_path([0, 0], [2, 2])
    # Multiple optimal paths exist; verify length and cost.
    assert_equal 5, path.size
    total_cost = path.each_cons(2).sum { |(x1,y1),(x2,y2)| @grid.cost(x2,y2) }
    assert_equal 4, total_cost # 4 moves each cost 1
  end

  def test_obstacle_avoidance
    # Place a high‑cost obstacle directly in the shortest route.
    @grid.set_cost(1, 0, Float::INFINITY)
    path = @astar.find_path([0, 0], [2, 0])
    expected = [[0,0],[0,1],[1,1],[2,1],[2,0]]
    assert_equal expected, path
  end

  def test_dynamic_cost_change
    # Initial path prefers the top row.
    path1 = @astar.find_path([0, 0], [4, 0])
    assert_equal [[0,0],[1,0],[2,0],[3,0],[4,0]], path1

    # Increase cost of middle cell, forcing a detour.
    @grid.set_cost(2, 0, 10)
    path2 = @astar.find_path([0, 0], [4, 0])
    refute_equal path1, path2
    # Verify that the new path avoids the expensive cell.
    assert_not_includes path2.map { |p| p[0] }, 2
  end

  def test_unreachable_goal
    # Surround goal with impassable cells.
    goal = [2,2]
    [[1,2],[2,1],[3,2],[2,3]].each { |x,y| @grid.set_cost(x, y, Float::INFINITY) }
    result = @astar.find_path([0,0], goal)
    assert_nil result
  end

  def test_start_equals_goal
    result = @astar.find_path([1,1], [1,1])
    assert_equal [[1,1]], result
  end

  # Simple benchmark to ensure deterministic runtime (not a performance test).
  def test_benchmark_small_grid
    start = Time.now
    100.times { @astar.find_path([0,0], [4,4]) }
    duration = Time.now - start
    assert_operator duration, :<, 2.0 # should finish well under 2 seconds on typical hardware
  end
end

if __FILE__ == $0
  # Running the test suite via Minitest's autorun.
end
