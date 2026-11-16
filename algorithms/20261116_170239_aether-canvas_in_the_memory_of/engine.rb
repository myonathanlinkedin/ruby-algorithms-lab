# frozen_string_literal: true

require_relative 'types'

# Canvas provides a mutable 2D raster stored in memory.
# It supports basic drawing primitives and flood fill.
class Canvas
  attr_reader :width, :height

  # Initialize a canvas of given dimensions.
  # All cells are filled with the default character (space by default).
  #
  # Raises ArgumentError if dimensions are non‑positive.
  def initialize(width, height, default_char = ' ')
    raise ArgumentError, 'width and height must be positive integers' unless width.is_a?(Integer) && height.is_a?(Integer) && width > 0 && height > 0
    @width = width
    @height = height
    @default_char = default_char
    @grid = Array.new(height) { Array.new(width, default_char) }
  end

  # Set the character at (x, y). (0,0) is top‑left.
  # Raises OutOfBoundsError if coordinates are outside the canvas.
  def set_pixel(x, y, char)
    validate_coordinates!(x, y)
    @grid[y][x] = char
    self
  end

  # Retrieve the character at (x, y).
  # Raises OutOfBoundsError if coordinates are outside the canvas.
  def get_pixel(x, y)
    validate_coordinates!(x, y)
    @grid[y][x]
  end

  # Draw a line using Bresenham's algorithm.
  # Supports any octant. The line includes both endpoints.
  def draw_line(x1, y1, x2, y2, char = '*')
    validate_coordinates!(x1, y1)
    validate_coordinates!(x2, y2)

    dx = (x2 - x1).abs
    dy = (y2 - y1).abs
    sx = x1 < x2 ? 1 : -1
    sy = y1 < y2 ? 1 : -1
    err = dx - dy

    x = x1
    y = y1
    loop do
      set_pixel(x, y, char)
      break if x == x2 && y == y2
      e2 = 2 * err
      if e2 > -dy
        err -= dy
        x += sx
      end
      if e2 < dx
        err += dx
        y += sy
      end
    end
    self
  end

  # Draw a rectangle outline. (x, y) is the top‑left corner.
  # Width and height must be at least 2 to form a visible outline.
  def draw_rect(x, y, rect_width, rect_height, char = '#')
    raise ArgumentError, 'rect_width and rect_height must be >= 2' unless rect_width >= 2 && rect_height >= 2
    validate_coordinates!(x, y)
    validate_coordinates!(x + rect_width - 1, y + rect_height - 1)

    # Top and bottom edges
    (x...(x + rect_width)).each { |cx| set_pixel(cx, y, char) }
    (x...(x + rect_width)).each { |cx| set_pixel(cx, y + rect_height - 1, char) }

    # Left and right edges
    (y...(y + rect_height)).each { |cy| set_pixel(x, cy, char) }
    (y...(y + rect_height)).each { |cy| set_pixel(x + rect_width - 1, cy, char) }
    self
  end

  # Flood fill (4‑connected) starting at (x, y) with the given character.
  # Cells already containing the fill character are left unchanged.
  def flood_fill(x, y, fill_char)
    validate_coordinates!(x, y)
    target_char = get_pixel(x, y)
    return self if target_char == fill_char

    stack = [[x, y]]
    while (cx, cy = stack.pop)
      next unless get_pixel(cx, cy) == target_char
      set_pixel(cx, cy, fill_char)

      # Push neighboring cells (4‑connected)
      stack << [cx + 1, cy] if cx + 1 < @width
      stack << [cx - 1, cy] if cx - 1 >= 0
      stack << [cx, cy + 1] if cy + 1 < @height
      stack << [cx, cy - 1] if cy - 1 >= 0
    end
    self
  end

  # Return a string representation of the canvas.
  # Each row ends with a newline; no trailing newline after the last row.
  def to_s
    @grid.map { |row| row.join }.join("\n")
  end

  private

  # Validate that (x, y) lies within the canvas bounds.
  def validate_coordinates!(x, y)
    unless x.is_a?(Integer) && y.is_a?(Integer) && x.between?(0, @width - 1) && y.between?(0, @height - 1)
      raise OutOfBoundsError, "coordinates (#{x}, #{y}) are outside the canvas"
    end
  end
end
