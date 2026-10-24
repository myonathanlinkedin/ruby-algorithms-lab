require_relative 'core'

require 'minitest/autorun'

class TestSelfHealingEvaluator < Minitest::Test
  def setup
    @evaluator = SelfHealing::ExpressionEvaluator.new
  end

  def test_simple_expression
    assert_in_delta 7.0, @evaluator.evaluate('3 + 4 * (2 - 1)'), 1e-9
  end

  def test_missing_operator
    assert_in_delta 5.0, @evaluator.evaluate('2 3'), 1e-9
  end

  def test_implicit_multiplication
    assert_in_delta 14.0, @evaluator.evaluate('2(3+4)'), 1e-9
  end

  def test_mismatched_parentheses
    assert_in_delta 3.0, @evaluator.evaluate('((1+2)'), 1e-9
  end

  def test_complex_healing
    expr = '5(6 7) + (8/ (2-2))' # multiple issues: implicit *, missing +, division by zero after healing
    assert_raises ZeroDivisionError do
      @evaluator.evaluate(expr)
    end
  end

  def test_division_by_zero_without_healing
    assert_raises ZeroDivisionError do
      @evaluator.evaluate('10 / 0')
    end
  end

  def test_invalid_character
    assert_raises SelfHealing::ParseError do
      @evaluator.evaluate('2 + a')
    end
  end

  def test_extra_operands
    assert_raises SelfHealing::ParseError do
      @evaluator.evaluate('1 2 3 +')
    end
  end

  def test_healing_no_change
    expr = '4 + 5'
    assert_in_delta 9.0, @evaluator.evaluate(expr), 1e-9
  end

  def test_floating_point
    assert_in_delta 3.5, @evaluator.evaluate('1.5 + 2.0'), 1e-9
  end

  def test_associativity
    assert_in_delta 0.0, @evaluator.evaluate('5 - 2 - 3'), 1e-9
  end

  def test_precedence
    assert_in_delta 7.0, @evaluator.evaluate('5 + 2 * 1'), 1e-9
  end
end

# Entry point for manual execution
if __FILE__ == $PROGRAM_NAME
  evaluator = SelfHealing::ExpressionEvaluator.new
  puts "Enter an arithmetic expression (or blank to exit):"
  while (line = STDIN.gets)
    line.strip!
    break if line.empty?
    begin
      result = evaluator.evaluate(line)
      puts "Result: #{result}"
    rescue => e
      puts "Error: #{e.class} – #{e.message}"
    end
    puts "Enter another expression (or blank to exit):"
  end
end
