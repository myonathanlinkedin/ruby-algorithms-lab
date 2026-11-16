# frozen_string_literal: true

# Simple immutable pixel representation
Pixel = Struct.new(:x, :y, :char) do
  def initialize(x, y, char = ' ')
    super(x, y, char)
  end
end

# Base error class for canvas operations
class CanvasError < StandardError; end

# Specific error for out-of-bounds access
class OutOfBoundsError < CanvasError; end
end
end
