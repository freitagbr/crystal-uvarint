require "./uvarint/*"

# This module is based on the varint implementation in the Go programming
# language. See: https://golang.org/src/encoding/binary/varint.go

MSB = 0x80_u8  # 10000000
REST = 0x7F_u8 # 01111111

module UVarint
  extend self

  alias UVarInt = Array(UInt8)

  # encode encodes a UInt64 into a UVarInt,
  # which is an Array of UInt8's.
  def encode(n : UInt64) : UVarInt
    buf = [] of UInt8
    while n >= MSB
      buf << (n.to_u8 | MSB)
      n = n >> 7
    end
    buf << n.to_u8
    return buf
  end

  # decode decodes a UVarInt into a UInt64.
  # If the UVarInt contains more than 10 UInt8's,
  # then an overflow exception is raised.
  def decode(vi : UVarInt) : UInt64
    x = 0_u64
    s = 0
    vi.each_with_index do |v, i|
      if v < MSB
        if i > 9 || i == 9 && v > 1
          raise Exception.new("overflow")
        end
        return x | (v.to_u64 << s)
      end
      x |= (v & REST).to_u64 << s
      s += 7
    end
    return 0_u64
  end
end
