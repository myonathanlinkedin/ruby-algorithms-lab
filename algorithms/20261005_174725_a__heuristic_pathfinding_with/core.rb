module Pathfinding
  # Simple binary min-heap for priority queue
  class MinHeap
    def initialize
      @data = []
    end

    def empty?
      @data.empty?
    end

    def push(item, priority)
      @data << [priority, item]
      sift_up(@data.size - 1)
    end

    def pop
      return nil if @data.empty?
      min = @data[0][1]
      if @data.size == 1
        @data.pop
      else
        @data[0] = @data.pop
        sift_down(0)
      end
      min
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

  # Grid encapsulates static and dynamic costs
  class Grid
    attr_reader :width, :height

    # costs: 2D array of base numeric costs (e.g., 1 for free, Float::INFINITY for impassable)
    # dynamic_cost: optional Proc taking (x, y, time) and returning a numeric cost
    def initialize(costs, dynamic_cost = nil)
      @costs = costs.map { |row| row.map(&:to_f) }
      @height = @costs.size
      @width = @costs.first.size
      @dynamic_cost = dynamic_cost
    end

    def in_bounds?(x, y)
      x.between?(0, @width - 1) && y.between?(0, @height - 1)
    end

    def base_cost(x, y)
      @costs[y][x]
    end

    def cost(x, y, time = nil)
      return Float::INFINITY unless in_bounds?(x, y)
      base = base_cost(x, y)
      return base if @dynamic_cost.nil?
      dyn = @dynamic_cost.call(x, y, time)
      base + dyn
    end

    # 4‑directional neighbors (no diagonals)
    def neighbors(x, y)
      [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]].select { |nx, ny| in_bounds?(nx, ny) }
    end
  end

  # A* implementation with optional dynamic cost handling
  class AStar
    # heuristic: Proc taking (x1, y1, x2, y2) => numeric
    # cost_func: Proc taking (grid, x, y, time) => numeric (overrides grid.cost)
    def initialize(grid, heuristic: nil, cost_func: nil)
      @grid = grid
      @heuristic = heuristic || method(:manhattan)
      @cost_func = cost_func
    end

    # start/goal are [x, y] arrays; start_time is optional integer
    def find_path(start, goal, start_time = 0)
      open_set = MinHeap.new
      open_set.push(start, 0)

      came_from = {}
      g_score = Hash.new(Float::INFINITY)
      g_score[start] = 0

      f_score = Hash.new(Float::INFINITY)
      f_score[start] = heuristic(start, goal)

      while (current = open_set.pop)
        return reconstruct_path(came_from, current) if current == goal

        cx, cy = current
        current_time = start_time + g_score[current]

        @grid.neighbors(cx, cy).each do |nx, ny|
          tentative_g = g_score[current] + edge_cost(cx, cy, nx, ny, current_time + 1)
          neighbor = [nx, ny]
          next if tentative_g >= g_score[neighbor]

          came_from[neighbor] = current
          g_score[neighbor] = tentative_g
          f_score[neighbor] = tentative_g + heuristic(neighbor, goal)
          open_set.push(neighbor, f_score[neighbor])
        end
      end
      nil # no path found
    end

    private

    def heuristic(a, b)
      @heuristic.call(a[0], a[1], b[0], b[1])
    end

    def manhattan(x1, y1, x2, y2)
      (x1 - x2).abs + (y1 - y2).abs
    end

    def edge_cost(x1, y1, x2, y2, time)
      if @cost_func
        @cost_func.call(@grid, x2, y2, time)
      else
        @grid.cost(x2, y2, time)
      end
    end

    def reconstruct_path(came_from, current)
      path = [current]
      while came_from.key?(current)
        current = came_from[current]
        path << current
      end
      path.reverse
    end
  end
end
