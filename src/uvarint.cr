require "./uvarint/*"

# This module is based on the varint implementation in the Go programming
# language. See: https://golang.org/src/encoding/binary/varint.go

MSB = 0x80_u8  # 10000000
REST = 0x7F_u8 # 01111111

struct UVarInt
  @encoded : Bytes
  @decoded : UInt64

  def initialize(int : Int::Unsigned)
    @decoded = int.to_u64
    @encoded = encode @decoded
  end

  def initialize(bytes : Bytes)
    @encoded = bytes
    @decoded = decode bytes
  end

  def initialize(en : Enumerable(UInt8))
    raise Exception.new "overflow" if en.size >= 10
    bytes = Bytes.new(en.size) { |i| en[i] }
    @encoded = bytes
    @decoded = decode bytes
  end

  # Accessors
  def encoded
    @encoded
  end

  def decoded
    @decoded
  end

  # encode encodes a UInt64 into a UVarInt,
  # which is an Array of UInt8's.
  private def encode(n : UInt64) : Bytes
    ptr = Pointer(UInt8).malloc 10
    i = 0
    while n >= MSB
      ptr[i] = n.to_u8 | MSB
      i += 1
      n = n >> 7
    end
    ptr[i] = n.to_u8
    Bytes.new(ptr, i + 1)
  end

  # decode decodes enumerable bytes into a UInt64.
  # If the enumeration is longer thar 10 bytes,
  # then an overflow exception is raised.
  private def decode(bytes : Bytes) : UInt64
    x = 0_u64
    s = 0
    bytes.each_with_index do |b, i|
      if b < MSB
        if i > 9 || i == 9 && b > 1
          raise Exception.new("overflow")
        end
        return x | (b.to_u64 << s)
      end
      x |= (b & REST).to_u64 << s
      s += 7
    end
    0_u64
  end
end
