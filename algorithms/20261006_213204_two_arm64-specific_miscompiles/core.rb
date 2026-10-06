module CurlBug
  # Provides deterministic arithmetic operations that can be used to
  # verify compiler correctness on various architectures (e.g., arm64).
  class MiscompileDemo
    MASK_64 = (1 << 64) - 1

    # Initialize with a binary string (ASCII-8BIT) or any object that
    # responds to #bytes.
    def initialize(data)
      @data = data.to_s.dup.force_encoding(Encoding::ASCII_8BIT)
    end

    # Compute a simple 64‑bit checksum: sum of all bytes modulo 2⁶⁴.
    # The algorithm is deliberately straightforward to make any
    # mis‑compilation obvious.
    def checksum
      sum = 0
      @data.each_byte { |b| sum = (sum + b) & MASK_64 }
      sum
    end

    # Rotate a 64‑bit integer left by +shift bits.
    # Shift is taken modulo 64.
    def rotate_left(value, shift)
      shift &= 63
      ((value << shift) | (value >> (64 - shift))) & MASK_64
    end

    # A more involved hash that mixes rotation, xor and addition.
    # This mimics patterns found in real‑world code (e.g., curl's hash
    # functions) while staying pure Ruby.
    def complex_hash
      h = 0xcbf29ce484222325 # FNV offset basis
      @data.each_byte do |b|
        h = rotate_left(h, 13) ^ b
        h = (h * 0x100000001b3) & MASK_64 # FNV prime
      end
      h
    end

    # Conditional branch that can be sensitive to compiler optimisations.
    # Returns true if the low 32 bits of the checksum are zero.
    def low32_zero?
      (checksum & 0xffffffff).zero?
    end
  end
end
