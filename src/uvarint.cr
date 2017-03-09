require "big/big_int"

require "./uvarint/*"

# This module is based on the varint implementation in the Go programming
# language. See: https://golang.org/src/encoding/binary/varint.go

private MSB = 0x80_u8
private REST = 0x7F_u8
private ZERO = 0.to_big_i

# Encodes an Int::Unsined into a Bytes slice.
private def encode(n : Int::Unsigned | BigInt) : Bytes
  arr = [] of UInt8
  while n >= MSB
    arr << (n.to_u8 | MSB)
    n = n >> 7
  end
  arr << n.to_u8
  ptr = arr.to_unsafe
  Bytes.new(ptr, arr.size)
end

# Decodes enumerable bytes into a BigInt.
# If the enumeration is longer thar 10 bytes,
# then an overflow exception is raised.
private def decode(bytes : Bytes) : BigInt
  x = ZERO
  s = 0
  bytes.each_with_index do |b, i|
    if b < MSB
      return x | (b.to_big_i << s)
    end
    x = x | ((b & REST).to_big_i << s)
    s += 7
  end
  ZERO
end

struct UVarInt
  @bytes : Bytes
  @uint : BigInt

  def initialize(uint : Int::Unsigned)
    @uint = uint.to_big_i
    @bytes = encode uint
  end

  def initialize(uint : BigInt)
    @uint = uint.to_big_i
    @bytes = encode uint
  end

  def initialize(bytes : Bytes)
    @bytes = bytes
    @uint = decode bytes
  end

  def initialize(en : Enumerable(UInt8))
    arr = en.to_a
    bytes = Bytes.new(arr.to_unsafe, arr.size)
    @bytes = bytes
    @uint = decode bytes
  end

  def initialize(str : String)
    arr = str.bytes
    bytes = Bytes.new(arr.to_unsafe, arr.size)
    @bytes = bytes
    @uint = decode bytes
  end

  # Accessors
  def bytes
    @bytes
  end

  def uint
    @uint
  end

  def to_s(base : Int32)
    @uint.to_s base
  end

  def hexstring
    @bytes.hexstring
  end

  macro [](*args)
    %bytes = Bytes[{{*args}}]
    UVarInt.new %bytes
  end

  {% begin %}
    {% for opt in %w(% * ** + - / << <=> === >>) %}
      def {{opt.id}}(other : UVarInt) : UVarInt
        UVarInt.new(@uint {{opt.id}} other.uint)
      end
    {% end %}

    {% for name, type in {
        to_i:   Int32,   to_u:   UInt32,  to_f:   Float64,
        to_i8:  Int8,    to_i16: Int16,   to_i32: Int32,  to_i64: Int64,
        to_u8:  UInt8,   to_u16: UInt16,  to_u32: UInt32, to_u64: UInt64,
        to_f32: Float32, to_f64: Float64,
    } %}
      # Returns *self* converted to {{type}}.
      def {{name.id}} : {{type}}
        @uint.{{name.id}}
      end
    {% end %}
  {% end %}
end
