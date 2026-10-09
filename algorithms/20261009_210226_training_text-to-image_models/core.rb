# frozen_string_literal: true

require 'zlib'

# Simple deterministic text encoder using CRC32.
class TextEncoder
  # Encodes a UTF-8 string into a 32‑bit unsigned integer seed.
  #
  # @param text [String] the prompt to encode
  # @return [Integer] a deterministic seed in 0..2**32‑1
  def self.encode(text)
    raise ArgumentError, 'text must be a String' unless text.is_a?(String)

    Zlib.crc32(text.encode('UTF-8')) & 0xffffffff
  end
end

# Represents a grayscale image as a 2‑D array of integers 0‑255.
class Image
  attr_reader :width, :height, :pixels

  # @param width [Integer] image width (>0)
  # @param height [Integer] image height (>0)
  # @param init_pixels [Array<Array<Integer>>] optional initial pixel matrix
  def initialize(width, height, init_pixels = nil)
    raise ArgumentError, 'width and height must be positive integers' unless width.is_a?(Integer) && height.is_a?(Integer) && width > 0 && height > 0

    @width = width
    @height = height
    @pixels = init_pixels || Array.new(height) { Array.new(width) { 0 } }
    validate_pixels!
  end

  # Returns a deep copy of the image.
  def dup
    Image.new(@width, @height, @pixels.map(&:dup))
  end

  # Returns the variance of pixel intensities.
  def variance
    flat = @pixels.flatten
    mean = flat.sum.to_f / flat.size
    flat.map { |v| (v - mean)**2 }.sum / flat.size
  end

  # Returns a simple ASCII representation (for debugging).
  def to_s
    chars = %w[ .:-=+*#%@]
    @pixels.map do |row|
      row.map { |v| chars[(v * (chars.size - 1) / 255).to_i] }.join
    end.join("\n")
  end

  private

  def validate_pixels!
    unless @pixels.size == @height && @pixels.all? { |row| row.size == @width && row.all? { |v| v.is_a?(Integer) && v.between?(0, 255) } }
      raise ArgumentError, 'pixels must be a height×width matrix of integers 0..255'
    end
  end
end

# A minimal diffusion model that iteratively denoises an image towards a target intensity.
class DiffusionModel
  # @param width [Integer] image width
  # @param height [Integer] image height
  # @param steps [Integer] number of diffusion steps (>=0)
  # @param seed [Integer] random seed for initial noise
  # @param target_intensity [Integer] desired final pixel value (0..255)
  def initialize(width:, height:, steps:, seed:, target_intensity: 128)
    raise ArgumentError, 'steps must be a non‑negative integer' unless steps.is_a?(Integer) && steps >= 0
    raise ArgumentError, 'target_intensity must be 0..255' unless target_intensity.is_a?(Integer) && target_intensity.between?(0, 255)

    @steps = steps
    @target = target_intensity
    @rng = Random.new(seed)
    @image = Image.new(width, height, random_noise(width, height))
  end

  # Runs the diffusion process and returns the final Image.
  #
  # @return [Image] denoised image
  def run
    @steps.times { diffusion_step }
    @image.dup
  end

  private

  # Generates initial random noise.
  def random_noise(w, h)
    Array.new(h) { Array.new(w) { @rng.rand(0..255) } }
  end

  # One diffusion iteration:
  #   each pixel moves a fraction towards the target and averages with its 4‑neighbourhood.
  def diffusion_step
    new_pixels = Array.new(@image.height) { Array.new(@image.width, 0) }

    @image.height.times do |y|
      @image.width.times do |x|
        current = @image.pixels[y][x]
        # Pull towards target (simple linear interpolation)
        pulled = ((current * (@steps - 1) + @target) / @steps.to_f).round
        # Average with orthogonal neighbours
        sum = pulled
        count = 1

        if x > 0
          sum += @image.pixels[y][x - 1]
          count += 1
        end
        if x < @image.width - 1
          sum += @image.pixels[y][x + 1]
          count += 1
        end
        if y > 0
          sum += @image.pixels[y - 1][x]
          count += 1
        end
        if y < @image.height - 1
          sum += @image.pixels[y + 1][x]
          count += 1
        end

        new_pixels[y][x] = (sum / count).round.clamp(0, 255)
      end
    end

    @image = Image.new(@image.width, @image.height, new_pixels)
  end
end

# High‑level trainer that ties a text prompt to a diffusion model.
class ModelTrainer
  DEFAULT_WIDTH = 32
  DEFAULT_HEIGHT = 16
  DEFAULT_STEPS = 20

  # @param prompt [String] textual description
  # @param width [Integer] image width
  # @param height [Integer] image height
  # @param steps [Integer] diffusion steps
  def initialize(prompt:, width: DEFAULT_WIDTH, height: DEFAULT_HEIGHT, steps: DEFAULT_STEPS)
    raise ArgumentError, 'prompt must be a String' unless prompt.is_a?(String)

    @prompt = prompt
    @seed = TextEncoder.encode(prompt)
    @target_intensity = (@seed % 256) # deterministic target based on prompt
    @model = DiffusionModel.new(
      width: width,
      height: height,
      steps: steps,
      seed: @seed,
      target_intensity: @target_intensity
    )
  end

  # Executes the training (diffusion) and returns the final Image.
  #
  # @return [Image] generated image
  def generate
    @model.run
  end

  # Exposes the internal seed for testing purposes.
  attr_reader :seed, :target_intensity
end
