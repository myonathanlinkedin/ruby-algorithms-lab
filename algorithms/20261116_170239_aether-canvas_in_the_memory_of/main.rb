# frozen_string_literal: true

require_relative 'types'
require_relative 'engine'
require 'test/unit'

# Unit tests for Canvas functionality.
class TestCanvas < Test::Unit::TestCase
  def test_initialization
    canvas = Canvas.new(5, 3, '.')
    assert_equal(5, canvas.width)
    assert_equal(3, canvas.height)
    expected = ".....\n.....\n....."
    assert_equal(expected, canvas.to_s)
  end

  def test_set_and_get_pixel
    canvas = Canvas.new(4, 2)
    canvas.set_pixel(1, 0, 'X')
    canvas.set_pixel(3, 1, 'Y')
    assert_equal('X', canvas.get_pixel(1, 0))
    assert_equal('Y', canvas.get_pixel(3, 1))
    assert_equal(' ', canvas.get_pixel(0, 0))
  end

  def test_out_of_bounds
    canvas = Canvas.new(2, 2)
    assert_raises(OutOfBoundsError) { canvas.set_pixel(-1, 0, '*') }
    assert_raises(OutOfBoundsError) { canvas.get_pixel(0, 2) }
    assert_raises(OutOfBoundsError) { canvas.draw_line(0, 0, 2, 2) }
  end

  def test_draw_line_horizontal
    canvas = Canvas.new(5, 1)
    canvas.draw_line(0, 0, 4, 0, '-')
    assert_equal('-----', canvas.to_s)
  end

  def test_draw_line_diagonal
    canvas = Canvas.new(5, 5)
    canvas.draw_line(0, 0, 4, 4, '\\')
    expected = <<~STR.chomp
      \\    
       \\   
        \\  
         \\ 
          \\
    STR
    assert_equal(expected, canvas.to_s)
  end

  def test_draw_rectangle
    canvas = Canvas.new(6, 4)
    canvas.draw_rect(1, 1, 4, 2, '#')
    expected = <<~STR.chomp
      ...... 
      .####. 
      .####. 
      ...... 
    STR
    # Remove trailing spaces for accurate comparison
    assert_equal(expected.gsub(' ', ''), canvas.to_s.gsub(' ', ''))
  end

  def test_flood_fill
    canvas = Canvas.new(3, 3, '.')
    canvas.set_pixel(1, 1, 'O')
    canvas.flood_fill(0, 0, '*')
    expected = <<~STR.chomp
      *** 
      *O* 
      *** 
    STR
    assert_equal(expected.gsub(' ', ''), canvas.to_s.gsub(' ', ''))
  end

  def test_complex_drawing
    canvas = Canvas.new(10, 6, '.')
    canvas.draw_rect(1, 1, 8, 4, '#')
    canvas.draw_line(0, 0, 9, 5, '/')
    canvas.flood_fill(5, 3, '~')
    expected = <<~STR.chomp
      /.........
      .########.
      .#~~~~~~#.
      .#~~~~~~#.
      .########.
      ........./
    STR
    assert_equal(expected, canvas.to_s)
  end
end

# Demonstration when the file is executed directly.
if __FILE__ == $0
  demo = Canvas.new(20, 10, '.')
  demo.draw_rect(2, 2, 16, 6, '#')
  demo.draw_line(0, 0, 19, 9, '*')
  demo.flood_fill(10, 5, '+')
  puts "Demo Canvas:"
  puts demo.to_s
end
