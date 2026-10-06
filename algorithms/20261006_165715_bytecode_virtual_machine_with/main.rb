require 'minitest/autorun'
require_relative 'core'

class TestBytecodeVM < Minitest::Test
  def setup
    @vm = BytecodeVM.new
  end

  def test_push_and_stack
    @vm.load([[:PUSH, 10], [:PUSH, 20]])
    @vm.run
    assert_equal [10, 20], @vm.stack
  end

  def test_add
    @vm.load([[:PUSH, 5], [:PUSH, 7], [:ADD], [:HALT]])
    @vm.run
    assert_equal [12], @vm.stack
  end

  def test_sub
    @vm.load([[:PUSH, 10], [:PUSH, 3], [:SUB], [:HALT]])
    @vm.run
    assert_equal [7], @vm.stack
  end

  def test_mul
    @vm.load([[:PUSH, 4], [:PUSH, 6], [:MUL], [:HALT]])
    @vm.run
    assert_equal [24], @vm.stack
  end

  def test_div
    @vm.load([[:PUSH, 20], [:PUSH, 4], [:DIV], [:HALT]])
    @vm.run
    assert_equal [5], @vm.stack
  end

  def test_div_by_zero
    @vm.load([[:PUSH, 5], [:PUSH, 0], [:DIV], [:HALT]])
    assert_raises(ZeroDivisionError) { @vm.run }
  end

  def test_print_output
    output = capture_io do
      @vm.load([[:PUSH, 42], [:PRINT], [:HALT]])
      @vm.run
    end
    assert_equal "42\n", output[0]
  end

  def test_unknown_opcode
    @vm.load([[:PUSH, 1], [:FOO], [:HALT]])
    assert_raises(RuntimeError) { @vm.run }
  end
end

if __FILE__ == $0
  program = [
    [:PUSH, 1], [:PUSH, 2], [:ADD],
    [:PUSH, 3], [:MUL],
    [:PRINT], [:HALT]
  ]
  vm = BytecodeVM.new
  vm.load(program)
  puts "Running sample program:"
  vm.run

  require 'benchmark'
  n = 100_000
  Benchmark.bm do |x|
    x.report("VM run") do
      n.times { vm.load(program); vm.run }
    end
  end
end
