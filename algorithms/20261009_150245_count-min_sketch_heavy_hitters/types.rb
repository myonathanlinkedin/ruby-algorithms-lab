# frozen_string_literal: true

# Parameter struct for Count-Min Sketch configuration
SketchConfig = Struct.new(:width, :depth) do
  def initialize(width, depth)
    raise ArgumentError, 'width must be positive integer' unless width.is_a?(Integer) && width > 0
    raise ArgumentError, 'depth must be positive integer' unless depth.is_a?(Integer) && depth > 0
    super(width, depth)
  end
end

# Simple immutable pair used for heavy‑hitter results
HeavyHitter = Struct.new(:item, :estimate) do
  def to_s
    "#{item}:#{estimate}"
  end
end
