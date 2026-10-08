module CP
  # Fast scanner for competitive programming
  class FastScanner
    def initialize(data = STDIN.read)
      @tokens = data.split
      @index = 0
    end

    def next
      token = @tokens[@index]
      @index += 1
      token
    end

    def next_int
      next.to_i
    end

    def next_str
      next
    end
  end

  # Modular arithmetic utilities
  module ModMath
    MOD = 1_000_000_007

    def self.mod_pow(base, exp, mod = MOD)
      result = 1
      b = base % mod
      e = exp
      while e > 0
        result = (result * b) % mod if (e & 1) == 1
        b = (b * b) % mod
        e >>= 1
      end
      result
    end

    def self.mod_inv(x, mod = MOD)
      mod_pow(x, mod - 2, mod)
    end
  end

  # Wrapper for modular integers
  class ModInt
    attr_reader :value

    def initialize(val, mod = ModMath::MOD)
      @mod = mod
      @value = ((val % @mod) + @mod) % @mod
    end

    def +(other)
      ModInt.new(@value + other.value, @mod)
    end

    def -(other)
      ModInt.new(@value - other.value, @mod)
    # rubocop:disable Style/OperatorMethodCall
    end

    def *(other)
      ModInt.new(@value * other.value, @mod)
    end

    def /(other)
      self * ModInt.new(ModMath.mod_inv(other.value, @mod), @mod)
    end

    def **(exp)
      ModInt.new(ModMath.mod_pow(@value, exp, @mod), @mod)
    end

    def ==(other)
      @value == other.value && @mod == other.instance_variable_get(:@mod)
    end

    def to_i
      @value
    end

    def to_s
      @value.to_s
    end
  # rubocop:enable Style/OperatorMethodCall
  end

  # Disjoint Set Union (Union-Find)
  class UnionFind
    def initialize(n)
      @parent = Array.new(n) { |i| i }
      @size = Array.new(n, 1)
    end

    def find(x)
      while @parent[x] != x
        @parent[x] = @parent[@parent[x]]
        x = @parent[x]
      end
      x
    end

    def union(x, y)
      xr = find(x)
      yr = find(y)
      return false if xr == yr

      if @size[xr] < @size[yr]
        xr, yr = yr, xr
      end
      @parent[yr] = xr
      @size[xr] += @size[yr]
      true
    end

    def same?(x, y)
      find(x) == find(y)
    end

    def component_size(x)
      @size[find(x)]
    end
  end

  # Fenwick Tree (Binary Indexed Tree) for prefix sums
  class FenwickTree
    def initialize(n)
      @n = n
      @bit = Array.new(n + 1, 0)
    end

    def add(idx, delta)
      i = idx + 1
      while i <= @n
        @bit[i] += delta
        i += i & -i
      end
    end

    def sum(idx)
      res = 0
      i = idx + 1
      while i > 0
        res += @bit[i]
        i -= i & -i
      end
      res
    end

    def range_sum(l, r)
      sum(r) - (l.zero? ? 0 : sum(l - 1))
    end
  end

  # Segment Tree for range sum queries and point updates
  class SegmentTree
    def initialize(arr)
      @n = arr.size
      @size = 1
      @size <<= 1 while @size < @n
      @data = Array.new(@size * 2, 0)
      arr.each_with_index { |v, i| @data[@size + i] = v }
      (@size - 1).downto(1) { |i| @data[i] = @data[i << 1] + @data[(i << 1) + 1] }
    end

    def update(idx, value)
      i = @size + idx
      @data[i] = value
      while i > 1
        i >>= 1
        @data[i] = @data[i << 1] + @data[(i << 1) + 1]
      end
    end

    def query(l, r) # inclusive l, exclusive r
      l += @size
      r += @size
      res = 0
      while l < r
        res += @data[l] if (l & 1) == 1
        res += @data[r - 1] if (r & 1) == 0
        l = (l + 1) >> 1
        r = (r - 1) >> 1
      end
      res
    end
  end
end
