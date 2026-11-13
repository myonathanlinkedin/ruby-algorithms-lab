require 'set'

# Simple representation of a bytecode instruction.
class Instruction
  attr_accessor :op, :args

  def initialize(op, *args)
    @op = op
    @args = args
  end

  def to_s
    "#{op} #{args.join(', ')}"
  end
end

# Basic block in a control‑flow graph.
class BasicBlock
  attr_accessor :name, :instrs, :succ, :pred, :idom, :dom_frontier, :children

  @@counter = 0
  def initialize(name = nil)
    @name = name || "B#{@@counter}"
    @@counter += 1
    @instrs = []
    @succ = Set.new
    @pred = Set.new
    @idom = nil
    @dom_frontier = Set.new
    @children = Set.new
  end

  def add_instr(instr)
    @instrs << instr
  end

  def terminator?
    return false if @instrs.empty?
    %i[jmp cjump ret].include?(@instrs.last.op)
  end

  def to_s
    lines = ["#{name}:"]
    @instrs.each { |i| lines << "  #{i}" }
    lines << "  succ: #{succ.map(&:name).join(', ')}"
    lines << "  pred: #{pred.map(&:name).join(', ')}"
    lines.join("\n")
  end
end

# Control‑flow graph builder.
class CFG
  attr_reader :blocks, :entry

  def initialize(instrs)
    @blocks = {}
    @entry = nil
    build_blocks(instrs)
    link_blocks
    compute_dominators
    compute_dom_frontiers
  end

  private

  # Split instructions into basic blocks.
  def build_blocks(instrs)
    current = nil
    instrs.each do |ins|
      if ins.op == :label
        current = (@blocks[ins.args[0]] ||= BasicBlock.new(ins.args[0]))
        @entry ||= current
      else
        current ||= (current = BasicBlock.new)
        @blocks[current.name] ||= current
        current.add_instr(ins)
        if %i[jmp cjump ret].include?(ins.op)
          current = nil
        end
      end
    end
  end

  # Establish successor / predecessor edges.
  def link_blocks
    @blocks.each_value do |blk|
      next if blk.instrs.empty?
      term = blk.instrs.last
      case term.op
      when :jmp
        target = @blocks[term.args[0]]
        blk.succ << target
        target.pred << blk
      when :cjump
        t1 = @blocks[term.args[1]]
        t2 = @blocks[term.args[2]]
        blk.succ << t1 << t2
        t1.pred << blk
        t2.pred << blk
      when :ret
        # no successors
      else
        # fall‑through to next block in textual order
        nxt = next_block(blk)
        if nxt
          blk.succ << nxt
          nxt.pred << blk
        end
      end
    end
  end

  def next_block(blk)
    keys = @blocks.keys
    idx = keys.index(blk.name)
    return nil unless idx && idx + 1 < keys.size
    @blocks[keys[idx + 1]]
  end

  # Iterative dominator computation (Lengauer‑Tarjan not required for small graphs).
  def compute_dominators
    all = @blocks.values.to_set
    @blocks.each_value { |b| b.idom = all }
    @entry.idom = Set[@entry]

    changed = true
    while changed
      changed = false
      @blocks.each_value do |b|
        next if b == @entry
        new_idom = b.pred.reduce(all) { |s, p| s & p.idom }
        new_idom << b
        if new_idom != b.idom
          b.idom = new_idom
          changed = true
        end
      end
    end

    # Immediate dominator extraction
    @blocks.each_value do |b|
      next if b == @entry
      idoms = b.idom - Set[b]
      b.idom = idoms.min_by { |x| x.idom.size } # crude but works for small graphs
    end

    # Build dominator tree children sets
    @blocks.each_value do |b|
      next if b.idom.is_a?(Set) # entry
      b.idom.children << b
    end
  end

  # Dominance frontier computation.
  def compute_dom_frontiers
    @blocks.each_value do |b|
      b.succ.each do |s|
        runner = b
        while runner && runner != s.idom
          runner.dom_frontier << s
          runner = runner.idom unless runner == @entry
        end
      end
    end
  end
end

# SSA conversion engine.
class SSAConverter
  attr_reader :cfg, :variables

  def initialize(cfg)
    @cfg = cfg
    @variables = Set.new
    collect_variables
    place_phi_functions
    rename_variables
  end

  # Returns a mapping block_name => list of SSA instructions.
  def ssa_blocks
    @cfg.blocks.transform_values { |b| b.instrs }
  end

  private

  # Gather all variable names appearing in assignments or uses.
  def collect_variables
    @cfg.blocks.each_value do |blk|
      blk.instrs.each do |ins|
        case ins.op
        when :assign
          @variables << ins.args[0]
        when :cjump, :jmp, :ret
          # ignore
        else
          # treat any arg that is a string and not a label as variable
          ins.args.each { |a| @variables << a if a.is_a?(String) && !a.start_with?('L') }
        end
      end
    end
  end

  # Insert phi nodes at dominance frontiers.
  def place_phi_functions
    work = Hash.new { |h, k| h[k] = [] }
    @variables.each { |v| work[v] = [] }

    @variables.each do |var|
      defs = defining_blocks(var)
      work[var] = defs.dup
      while !work[var].empty?
        b = work[var].pop
        b.dom_frontier.each do |df|
          unless phi_exists?(df, var)
            phi = Instruction.new(:phi, var, {})
            df.instrs.unshift(phi)
            work[var] << df unless defs.include?(df)
          end
        end
      end
    end
  end

  def defining_blocks(var)
    defs = Set.new
    @cfg.blocks.each_value do |blk|
      blk.instrs.each do |ins|
        if ins.op == :assign && ins.args[0] == var
          defs << blk
          break
        end
      end
    end
    defs
  end

  def phi_exists?(blk, var)
    blk.instrs.any? { |ins| ins.op == :phi && ins.args[0] == var }
  end

  # Rename variables using a depth‑first walk of the dominator tree.
  def rename_variables
    counters = Hash.new(0)
    stacks = Hash.new { |h, k| h[k] = [] }

    rename_block(@cfg.entry, counters, stacks)
  end

  def rename_block(block, counters, stacks)
    # Rename phi destinations first
    block.instrs.each do |ins|
      next unless ins.op == :phi
      var = ins.args[0]
      new_name = "#{var}_#{counters[var]}"
      counters[var] += 1
      stacks[var] << new_name
      ins.args[0] = new_name
    end

    # Rename instructions inside block
    block.instrs.each do |ins|
      case ins.op
      when :assign
        src = ins.args[1]
        src_ren = rename_use(src, stacks)
        ins.args[1] = src_ren if src_ren
        var = ins.args[0]
        new_name = "#{var}_#{counters[var]}"
        counters[var] += 1
        stacks[var] << new_name
        ins.args[0] = new_name
      when :phi
        # already handled
      else
        # rename uses in args
        ins.args.map! { |a| rename_use(a, stacks) || a }
      end
    end

    # Update phi arguments of successors
    block.succ.each do |s|
      s.instrs.each do |ins|
        next unless ins.op == :phi
        var = ins.args[0].split('_').first
        version = stacks[var].last
        ins.args[1][block.name] = version
      end
    end

    # Recurse into children in dominator tree
    block.children.each do |child|
      rename_block(child, counters.dup, stacks.transform_values(&:dup))
    end

    # Pop names defined in this block
    block.instrs.reverse.each do |ins|
      case ins.op
      when :assign
        var = ins.args[0].split('_').first
        stacks[var].pop
      when :phi
        var = ins.args[0].split('_').first
        stacks[var].pop
      end
    end
  end

  def rename_use(arg, stacks)
    return nil unless arg.is_a?(String)
    return nil if arg.start_with?('L') # label
    if stacks.key?(arg) && !stacks[arg].empty?
      stacks[arg].last
    else
      nil
    end
  end
end
