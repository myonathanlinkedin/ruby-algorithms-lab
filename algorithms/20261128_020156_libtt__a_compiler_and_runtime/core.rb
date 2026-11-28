# Libtt: A Compiler and Runtime for Tenstorrent Processors
# Pure Ruby reference implementation.
#
# This module models the core abstractions of a compiler/runtime for
# Tenstorrent-style AI accelerators:
#   - Tensor: immutable n-dimensional array with shape and dtype
#   - Op:      algebraic operations (add, mul, matmul, relu, etc.)
#   - Graph:   directed acyclic graph of ops (intermediate representation)
#   - Compiler: passes that transform the graph (fusion, constant folding)
#   - Runtime:  topological execution engine with tiling and scheduling
#
# Invariants:
#   - Graph is a DAG (no cycles).
#   - All tensor shapes are validated at construction and op time.
#   - Execution is deterministic: same graph + same inputs => same outputs.
#   - Time complexity of topological sort: O(V + E).
#   - Space complexity of graph storage: O(V + E).

module Libtt
  # Supported data types
  module Dtype
    F32 = :f32
    F16 = :f16
    I32 = :i32
    I8  = :i8
  end

  # Immutable n-dimensional tensor.
  # Data is stored in row-major (C) order as a flat Array.
  class Tensor
    attr_reader :shape, :dtype, :data

    # @param shape [Array<Integer>] e.g. [2, 3]
    # @param dtype [Symbol] one of Dtype constants
    # @param data  [Array<Numeric>] flat row-major data, length must equal shape product
    def initialize(shape, dtype, data)
      @shape = shape.map(&:to_i)
      @dtype = dtype
      expected = @shape.reduce(1, :*)
      raise ArgumentError, "data length #{data.length} != shape product #{expected}" unless data.length == expected
      @data = data.dup.freeze
    end

    def size
      @shape.reduce(1, :*)
    end

    def ndim
      @shape.length
    end

    # Return a 2D slice [i][j] for a 2D tensor.
    def at(i, j)
      raise ArgumentError, 'at(i,j) requires 2D tensor' unless @shape.length == 2
      @data[i * @shape[1] + j]
    end

    def to_a
      @data.dup
    end

    def ==(other)
      other.is_a?(Tensor) && @shape == other.shape && @dtype == other.dtype && @data == other.data
    end

    def hash
      [@shape, @dtype, @data].hash
    end

    def inspect
      "Tensor(shape=#{@shape.inspect}, dtype=#{@dtype}, data=#{@data.inspect})"
    end
  end

  # Abstract base for all operations in the graph.
  class Op
    attr_reader :name, :inputs, :output_shape, :output_dtype

    def initialize(name, inputs, output_shape, output_dtype)
      @name = name
      @inputs = inputs
      @output_shape = output_shape
      @output_dtype = output_dtype
    end

    # Subclasses must implement: compute(input_tensors) -> Tensor
    def compute(_input_tensors)
      raise NotImplementedError, "#{self.class}#compute not implemented"
    end
  end

  # Element-wise addition: A + B (broadcast not supported; shapes must match).
  class AddOp < Op
    def initialize(a, b)
      validate_same_shape(a, b)
      super('add', [a, b], a.shape, a.dtype)
    end

    def compute(inputs)
      a, b = inputs
      result = a.data.zip(b.data).map { |x, y| x + y }
      Tensor.new(@output_shape, @output_dtype, result)
    end

    private

    def validate_same_shape(a, b)
      raise ArgumentError, "shape mismatch: #{a.shape} vs #{b.shape}" unless a.shape == b.shape
    end
  end

  # Element-wise multiplication: A * B.
  class MulOp < Op
    def initialize(a, b)
      validate_same_shape(a, b)
      super('mul', [a, b], a.shape, a.dtype)
    end

    def compute(inputs)
      a, b = inputs
      result = a.data.zip(b.data).map { |x, y| x * y }
      Tensor.new(@output_shape, @output_dtype, result)
    end

    private

    def validate_same_shape(a, b)
      raise ArgumentError, "shape mismatch: #{a.shape} vs #{b.shape}" unless a.shape == b.shape
    end
  end

  # Matrix multiplication: A (m x k) * B (k x n) => (m x n).
  # Time: O(m * k * n). Space: O(m * n).
  class MatMulOp < Op
    def initialize(a, b)
      raise ArgumentError, 'matmul requires 2D tensors' unless a.ndim == 2 && b.ndim == 2
      k1 = a.shape[1]
      k2 = b.shape[0]
      raise ArgumentError, "inner dim mismatch: #{k1} != #{k2}" unless k1 == k2
      super('matmul', [a, b], [a.shape[0], b.shape[1]], a.dtype)
    end

    def compute(inputs)
      a, b = inputs
      m, k = a.shape
      n = b.shape[1]
      result = Array.new(m * n, 0)
      m.times do |i|
        k.times do |p|
          a_val = a.data[i * k + p]
          next if a_val.zero?
          n.times do |j|
            result[i * n + j] += a_val * b.data[p * n + j]
          end
        end
      end
      Tensor.new(@output_shape, @output_dtype, result)
    end
  end

  # Element-wise ReLU: max(0, x).
  class ReluOp < Op
    def initialize(a)
      super('relu', [a], a.shape, a.dtype)
    end

    def compute(inputs)
      a = inputs[0]
      result = a.data.map { |x| x > 0 ? x : 0 }
      Tensor.new(@output_shape, @output_dtype, result)
    end
  end

  # Constant tensor node (leaf).
  class ConstantOp < Op
    def initialize(tensor)
      super('const', [], tensor.shape, tensor.dtype)
      @const_tensor = tensor
    end

    def compute(_inputs)
      @const_tensor
    end
  end

  # Directed acyclic graph of ops.
  # Nodes are Op instances; edges are implicit via Op#inputs.
  class Graph
    attr_reader :nodes, :edges, :inputs, :outputs

    def initialize
      @nodes = {}   # ObjectID => Op
      @edges = {}   # ObjectID => Set of ObjectID (successors)
      @inputs = []  # leaf tensors (no-op inputs)
      @outputs = [] # designated output tensors
    end

    # Register an op node. Returns the op.
    def add_node(op)
      id = op.object_id
      @nodes[id] = op
      @edges[id] = Set.new
      op.inputs.each do |input_tensor|
        # Find the producer op of input_tensor if it is an op output
        producer = find_producer(input_tensor)
        if producer
          pid = producer.object_id
          @edges[pid] ||= Set.new
          @edges[pid] << id
        end
      end
      op
    end

    def set_inputs(tensors)
      @inputs = tensors
    end

    def set_outputs(tensors)
      @outputs = tensors
    end

    def node_count
      @nodes.length
    end

    def edge_count
      @edges.values.reduce(0) { |sum, s| sum + s.length }
    end

    # Topological sort using Kahn's algorithm.
    # Time: O(V + E). Space: O(V + E).
    # Returns array of Op in topological order.
    def topological_sort
      in_degree = {}
      @nodes.each_key { |id| in_degree[id] = 0 }
      @edges.each do |src, dsts|
        dsts.each { |dst| in_degree[dst] += 1 }
      end

      queue = in_degree.select { |_id, deg| deg.zero? }.keys
      order = []
      while (id = queue.shift)
        order << @nodes[id]
        (@edges[id] || Set.new).each do |dst|
          in_degree[dst] -= 1
          queue << dst if in_degree[dst].zero?
        end
      end

      raise 'Cycle detected in graph' if order.length != @nodes.length
      order
    end

    private

    # Find the op that produced a given tensor (by identity).
    def find_producer(tensor)
      @nodes.each_value do |op|
        return op if op.respond_to?(:output_tensor) && op.output_tensor.equal?(tensor)
      end
      nil
    end
  end

  # Compiler: applies optimization passes to a Graph.
  class Compiler
    attr_reader :graph

    def initialize(graph)
      @graph = graph
    end

    # Pass 1: Constant folding.
    # If an op has all constant inputs, replace it with a ConstantOp.
    # Time: O(V). Space: O(V).
    def constant_fold
      order = @graph.topological_sort
      folded = {}
      order.each do |op|
        if op.is_a?(ConstantOp)
          folded[op.object_id] = op
          next
        end
        all_const = op.inputs.all? { |t| folded.values.any? { |c| c.is_a?(ConstantOp) && c.output_tensor.equal?(t) } }
        if all_const
          result = op.compute(op.inputs)
          new_op = ConstantOp.new(result)
          folded[op.object_id] = new_op
        else
          folded[op.object_id] = op
        end
      end
      folded
    end

    # Pass 2: Op fusion.
    # Fuse consecutive element-wise ops (add+relu, mul+relu) into a single fused op.
    # Returns a hash of fused op groups.
    def fuse_ops
      order = @graph.topological_sort
      fused_groups = []
      visited = Set.new
      order.each do |op|
        next if visited.include?(op.object_id)
        group = [op]
        visited << op.object_id
        # Try to fuse with successor if it is element-wise
        successors = find_successors(op)
        successors.each do |succ|
          if element_wise?(succ) && !visited.include?(succ.object_id)
            group << succ
            visited << succ.object_id
          end
        end
        fused_groups << group if group.length > 1
      end
      fused_groups
    end

    # Run all passes. Returns a summary hash.
    def optimize
      folded = constant_fold
      fused = fuse_ops
      {
        constant_folded: folded.count { |_id, op| op.is_a?(ConstantOp) },
        fused_groups: fused.length,
        total_nodes: @graph.node_count
      }
    end

    private

    def element_wise?(op)
      op.is_a?(AddOp) || op.is_a?(MulOp) || op.is_a?(ReluOp)
    end

    def find_successors(op)
      id = op.object_id
      (@graph.edges[id] || Set.new).map { |dst_id| @graph.nodes[dst_id] }.compact
    end
  end

  # Runtime: executes a compiled graph topologically.
  # Time: O(V + E + sum of op compute costs).
  # Space: O(V) for intermediate tensors.
  class Runtime
    attr_reader :graph, :compiler

    def initialize(graph)
      @graph = graph
      @compiler = Compiler.new(graph)
    end

    # Execute the graph.
    # @param input_map [Hash] maps input Tensor objects to their values (or uses the tensor itself).
    # @return [Array<Tensor>] output tensors in the order specified by graph#outputs.
    def execute(input_map = {})
      order = @graph.topological_sort
      tensor_cache = {}

      # Seed input tensors
      @graph.inputs.each do |t|
        tensor_cache[t.object_id] = input_map[t] || t
      end

      order.each do |op|
        next if tensor_cache.key?(op.object_id)
        if op.is_a?(ConstantOp)
          tensor_cache[op.object_id] = op.compute([])
        else
          input_tensors = op.inputs.map do |t|
            tensor_cache[t.object_id] || raise("Missing input tensor for op #{op.name}")
          end
          tensor_cache[op.object_id] = op.compute(input_tensors)
        end
      end

      @graph.outputs.map do |t|
        tensor_cache[t.object_id] || raise("Missing output tensor")
      end
    end
  end
end
