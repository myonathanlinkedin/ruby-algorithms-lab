require 'digest'

class HyperLogLog
  attr_reader :precision, :registers

  # precision: number of bits used for the register index (p)
  # Typical values: 4 <= p <= 16 (m = 2^p registers)
  def initialize(precision = 12)
    raise ArgumentError, "precision must be between 4 and 16" unless (4..16).include?(precision)
    @precision = precision
    @m = 1 << precision
    @registers = Array.new(@m, 0)
  end

  # Add an element (any object that responds to #to_s)
  def add(item)
    hash = hash64(item)
    idx = (hash >> (64 - @precision)).to_i
    w = (hash << @precision) & ((1 << 64) - 1) # remaining bits after index
    rank = leading_zeros(w, 64 - @precision) + 1
    @registers[idx] = rank if rank > @registers[idx]
    self
  end

  # Estimate cardinality
  def count
    m = @m
    sum = 0.0
    @registers.each { |r| sum += 2.0 ** -r }
    estimate = alpha * m * m / sum

    # Small range correction (linear counting)
    if estimate <= 5.0 * m / 2.0
      v = @registers.count(0)
      return m * Math.log(m.to_f / v) if v != 0
    end

    # Large range correction
    if estimate > (1.0 / 30.0) * (1 << 64)
      return - (1 << 64) * Math.log(1.0 - estimate / (1 << 64))
    end

    estimate
  end

  # Merge another HyperLogLog into this one (in‑place)
  def merge!(other)
    raise ArgumentError, "precision mismatch" unless other.precision == @precision
    @registers.each_index do |i|
      @registers[i] = other.registers[i] if other.registers[i] > @registers[i]
    end
    self
  end

  private

  # Bias correction constant α_m
  def alpha
    case @m
    when 16 then 0.673
    when 32 then 0.697
    when 64 then 0.709
    else 0.7213 / (1 + 1.079 / @m)
    end
  end

  # Deterministic 64‑bit hash using SHA‑256 (first 8 bytes, big‑endian)
  def hash64(item)
    digest = Digest::SHA256.digest(item.to_s)
    digest[0, 8].unpack1('Q>') # unsigned 64‑bit integer
  end

  # Count leading zeros in a bits‑wide integer
  def leading_zeros(x, bits)
    count = 0
    (bits - 1).downto(0) do |i|
      if (x & (1 << i)).zero?
        count += 1
      else
        break
      end
    end
    count
  end
end
