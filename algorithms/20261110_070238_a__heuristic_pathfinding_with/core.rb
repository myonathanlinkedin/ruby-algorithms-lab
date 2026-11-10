# A* pathfinding implementation with dynamic obstacle costs.
# Uses a simple binary min‑heap for the open set.
# Time complexity: O(E log V) where E = edges, V = vertices.
# Space complexity: O(V).

class Grid
  attr_reader :width, :height

  # Initialize a width × height grid.
  # Each cell defaults to traversal cost 1.
  def initialize(width, height, default_cost = 1)
    @width = width
    @height = height
    @costs = Array.new(height) { Array.new(width, default_cost) }
  end

  # Set traversal cost for a cell (x, y).
  # Use Float::INFINITY to represent an impassable obstacle.
  def set_cost(x, y, cost)
    validate_coords!(x, y)
    @costs[y][x] = cost
  end

  # Retrieve traversal cost for a cell (x, y).
  def cost(x, y)
    validate_coords!(x, y)
    @costs[y][x]
  end

  # Return 4‑directional walkable neighbours of (x, y).
  # Neighbours with cost Float::INFINITY are still returned;
  # the A* algorithm will treat them as non‑traversable.
  def neighbours(x, y)
    dirs = [[1,0], [-1,0], [0,1], [0,-1]]
    dirs.map { |dx, dy| [x + dx, y + dy] }
        .select { |nx, ny| inside?(nx, ny) }
  end

  private

  def inside?(x, y)
    x.between?(0, @width - 1) && y.between?(0, @height - 1)
  end

  def validate_coords!(x, y)
    raise ArgumentError, "Coordinates out of bounds (#{x},#{y})" unless inside?(x, y)
  end
end

# Simple binary min‑heap priority queue.
class MinHeap
  def initialize
    @data = []
    @counter = 0 # tie‑breaker to ensure deterministic ordering
  end

  def push(priority, item)
    @data << [priority, @counter, item]
    @counter += 1
    sift_up(@data.size - 1)
    self
  end

  def pop
    return nil if empty?
    min = @data[0][2]
    if @data.size == 1
      @data.pop
    else
      @data[0] = @data.pop
      sift_down(0)
    end
    min
  end

  def empty?
    @data.empty?
  end

  private

  def sift_up(idx)
    while idx > 0
      parent = (idx - 1) / 2
      break if @data[parent][0] <= @data[idx][0]
      @data[parent], @data[idx] = @data[idx], @data[parent]
      idx = parent
    end
  end

  def sift_down(idx)
    size = @data.size
    loop do
      left = idx * 2 + 1
      right = left + 1
      smallest = idx

      smallest = left if left < size && @data[left][0] < @data[smallest][0]
      smallest = right if right < size && @data[right][0] < @data[smallest][0]

      break if smallest == idx
      @data[smallest], @data[idx] = @data[idx], @data[smallest]
      idx = smallest
    end
  end
end

class AStar
  # grid: instance of Grid
  def initialize(grid)
    @grid = grid
  end

  # Find shortest‑cost path from start to goal.
  # start, goal: [x, y] arrays.
  # Returns array of coordinates including start and goal, or nil if unreachable.
  def find_path(start, goal)
    sx, sy = start
    gx, gy = goal
    validate_point!(sx, sy)
    validate_point!(gx, gy)

    return [start] if start == goal

    open_set = MinHeap.new
    open_set.push(heuristic(start, goal), start)

    came_from = {}
    g_score = Hash.new(Float::INFINITY)
    g_score[start] = 0.0

    f_score = Hash.new(Float::INFINITY)
    f_score[start] = heuristic(start, goal)

    while (current = open_set.pop)
      return reconstruct_path(came_from, current) if current == goal

      cx, cy = current
      @grid.neighbours(cx, cy).each do |nx, ny|
        tentative_g = g_score[current] + @grid.cost(nx, ny)
        next if @grid.cost(nx, ny) == Float::INFINITY # impassable

        neighbor = [nx, ny]
        if tentative_g < g_score[neighbor]
          came_from[neighbor] = current
          g_score[neighbor] = tentative_g
          f_score[neighbor] = tentative_g + heuristic(neighbor, goal)
          open_set.push(f_score[neighbor], neighbor)
        end
      end
    end

    nil # no path found
  end

  private

  # Manhattan distance (admissible for 4‑directional movement).
  def heuristic(a, b)
    (a[0] - b[0]).abs + (a[1] - b[1]).abs
  end

  def reconstruct_path(came_from, current)
    path = [current]
    while came_from.key?(current)
      current = came_from[current]
      path << current
    end
    path.reverse
  end

  def validate_point!(x, y)
    raise ArgumentError, "Point out of bounds (#{x},#{y})" unless @grid.send(:inside?, x, y)
  end
end
