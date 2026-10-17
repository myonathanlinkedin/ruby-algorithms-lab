# frozen_string_literal: true

require 'minitest/autorun'
require 'benchmark'
require_relative 'core'

# Unit tests for the pure‑Ruby diffusion implementation.
class DiffusionTest < Minitest::Test
  def test_text_encoder_determinism
    prompt = 'A sunny meadow with butterflies.'
    seed1 = TextEncoder.encode(prompt)
    seed2 = TextEncoder.encode(prompt.dup)
    assert_equal seed1, seed2
    refute_equal seed1, TextEncoder.encode('different prompt')
  end

  def test_image_variance_decreases
    trainer = ModelTrainer.new(prompt: 'gradient test', steps: 10, width: 8, height: 8)
    initial_image = trainer.instance_variable_get(:@model).instance_variable_get(:@image)
    initial_variance = initial_image.variance

    final_image = trainer.generate
    final_variance = final_image.variance

    assert_operator final_variance, :<=, initial_variance
  end

  def test_different_prompts_yield_different_targets
    trainer_a = ModelTrainer.new(prompt: 'cat', steps: 5, width: 4, height: 4)
    trainer_b = ModelTrainer.new(prompt: 'dog', steps: 5, width: 4, height: 4)

    assert_not_equal trainer_a.target_intensity, trainer_b.target_intensity

    img_a = trainer_a.generate
    img_b = trainer_b.generate

    # Simple pixel‑wise comparison; at least one pixel must differ.
    diff = img_a.pixels.zip(img_b.pixels).any? do |row_a, row_b|
      row_a.zip(row_b).any? { |a, b| a != b }
    end
    assert diff, 'Images from different prompts should not be identical'
  end

  def test_zero_steps_returns_initial_noise
    trainer = ModelTrainer.new(prompt: 'static', steps: 0, width: 3, height: 3)
    # With zero steps diffusion_step is never called; the model should return the initial noise.
    image = trainer.generate
    # Since no denoising occurs, variance should be close to that of a uniform random distribution.
    # We only assert that the image is valid and not all pixels equal.
    flat = image.pixels.flatten
    assert_operator flat.uniq.size, :>, 1
  end

  def test_invalid_dimensions_raise
    assert_raises(ArgumentError) { Image.new(0, 5) }
    assert_raises(ArgumentError) { Image.new(5, -1) }
  end
end

# Simple benchmark demonstrating runtime scaling with steps.
if __FILE__ == $PROGRAM_NAME
  puts 'Benchmark: diffusion steps vs runtime (ms)'
  widths = [32, 64]
  steps_set = [5, 10, 20]

  widths.each do |w|
    steps_set.each do |s|
      time = Benchmark.realtime do
        trainer = ModelTrainer.new(prompt: "benchmark w#{w}s#{s}", width: w, height: w / 2, steps: s)
        trainer.generate
      end
      puts format('Width: %3d, Steps: %2d => %6.2f ms', w, s, time * 1000)
    end
  end

  # Demonstration output
  demo = ModelTrainer.new(prompt: 'demo image', width: 16, height: 8, steps: 15).generate
  puts "\nGenerated ASCII image (demo):"
  puts demo.to_s
end
