require_relative 'core'
require 'minitest/autorun'

class TestSSAConversion < Minitest::Test
  def setup
    @instrs = [
      Instruction.new(:label, 'entry'),
      Instruction.new(:assign, 'a', 1),
      Instruction.new(:cjump, 'a', 'L1', 'L2'),
      Instruction.new(:label, 'L1'),
      Instruction.new(:assign, 'a', 2),
      Instruction.new(:jmp, 'L3'),
      Instruction.new(:label, 'L2'),
      Instruction.new(:assign, 'a', 3),
      Instruction.new(:label, 'L3'),
      Instruction.new(:ret, 'a')
    ]
    @cfg = CFG.new(@instrs)
    @ssa = SSAConverter.new(@cfg)
  end

  def test_phi_insertion
    block_l3 = @cfg.blocks['L3']
    phi = block_l3.instrs.find { |i| i.op == :phi && i.args[0].start_with?('a_') }
    refute_nil phi, 'Phi node for a should be inserted at L3'
    # Ensure phi has two incoming versions
    assert_equal 2, phi.args[1].size
    incoming = phi.args[1].values
    assert incoming.all? { |v| v.start_with?('a_') }
  end

  def test_renaming_uniqueness
    names = []
    @ssa.ssa_blocks.each_value do |instrs|
      instrs.each do |ins|
        case ins.op
        when :assign, :phi
          names << ins.args[0]
        end
      end
    end
    assert_equal names.uniq.size, names.size, 'All SSA variable names must be unique'
  end

  def test_ret_uses_latest_version
    ret = @cfg.blocks['L3'].instrs.find { |i| i.op == :ret }
    version = ret.args[0]
    assert_match(/^a_\d+$/, version, 'Return should use an SSA version of a')
  end
end

# Simple benchmark (optional)
if __FILE__ == $0
  require 'benchmark'

  puts "Running SSA conversion benchmark..."
  n = 1000
  instrs = []
  n.times do |i|
    instrs << Instruction.new(:label, "L#{i}")
    instrs << Instruction.new(:assign, "x", i)
    instrs << Instruction.new(:cjump, "x", "L#{i+1}", "L#{i+2}") if i < n - 2
  end
  instrs << Instruction.new(:label, "L#{n}")
  instrs << Instruction.new(:ret, "x")

  cfg = CFG.new(instrs)
  time = Benchmark.realtime { SSAConverter.new(cfg) }
  puts "Converted #{n} blocks in #{(time * 1000).round(2)} ms"
end
