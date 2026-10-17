class BytecodeVM
  OPCODES = {
    :PUSH  => 0,
    :ADD   => 1,
    :SUB   => 2,
    :MUL   => 3,
    :DIV   => 4,
    :PRINT => 5,
    :HALT  => 6
  }

  def initialize
    @stack   = []
    @ip      = 0
    @bytecode = []
    @running = false
  end

  def load(bytecode)
    @bytecode = bytecode
    @ip = 0
  end

  def run
    @running = true
    while @running && @ip < @bytecode.size
      instr = @bytecode[@ip]
      case instr[0]
      when :PUSH
        @stack << instr[1]
      when :ADD
        b = @stack.pop
        a = @stack.pop
        @stack << a + b
      when :SUB
        b = @stack.pop
        a = @stack.pop
        @stack << a - b
      when :MUL
        b = @stack.pop
        a = @stack.pop
        @stack << a * b
      when :DIV
        b = @stack.pop
        a = @stack.pop
        raise ZeroDivisionError if b == 0
        @stack << a / b
      when :PRINT
        puts @stack.last
      when :HALT
        @running = false
      else
        raise "Unknown opcode #{instr[0]}"
      end
      @ip += 1
    end
  end

  def stack
    @stack.dup
  end

  def ip
    @ip
  end
end
