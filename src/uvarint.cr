require "./uvarint/*"

# This module is based on the varint implementation in the Go programming
# language. See: https://golang.org/src/encoding/binary/varint.go

# Encodes an Int::Unsined into a Bytes slice.
private def encode(n : Int::Unsigned) : Bytes
  ptr = Pointer(UInt8).malloc 10
  i = 0
  while n >= 0x80_u8
    ptr[i] = n.to_u8 | 0x80_u8
    i += 1
    n = n >> 7
  end
  ptr[i] = n.to_u8
  Bytes.new(ptr, i + 1)
end

# Decodes enumerable bytes into a UInt64.
# If the enumeration is longer thar 10 bytes,
# then an overflow exception is raised.
private def decode(bytes : Bytes) : UInt64
  x = 0_u64
  s = 0
  bytes.each_with_index do |b, i|
    if b < 0x80_u8
      if i > 9 || i == 9 && b > 1
        raise Exception.new "overflow"
      end
      return x | (b.to_u64 << s)
    end
    x |= (b & 0x7F_u8).to_u64 << s
    s += 7
  end
  0_u64
end

struct UVarInt
  @encoded : Bytes
  @decoded : UInt64

  def initialize(uint : Int::Unsigned)
    @decoded = uint.to_u64
    @encoded = encode uint
  end

  def initialize(bytes : Bytes)
    raise ArgumentError.new "cannot initialize with more than 10 bytes" if bytes.size > 10
    @encoded = bytes
    @decoded = decode bytes
  end

  def initialize(en : Enumerable(UInt8))
    raise ArgumentError.new "cannot initialize with more than 10 bytes" if en.size > 10
    arr = en.to_a
    bytes = Bytes.new(arr.to_unsafe, arr.size)
    @encoded = bytes
    @decoded = decode bytes
  end

  def initialize(str : String)
    raise ArgumentError.new "cannot initialize with more than 10 bytes" if str.size > 10
    arr = str.bytes
    bytes = Bytes.new(arr.to_unsafe, arr.size)
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

  {% begin %}
    {% for opt in %w(% * ** + - / << <=> === >>) %}
      def {{opt.id}}(other : UVarInt) : UInt64
        @decoded {{opt.id}} other.decoded
      end
    {% end %}

    {% for name, type in {
        to_i: Int32, to_u: UInt32, to_f: Float64,
        to_i8: Int8, to_i16: Int16, to_i32: Int32, to_i64: Int64,
        to_u8: UInt8, to_u16: UInt16, to_u32: UInt32, to_u64: UInt64,
        to_f32: Float32, to_f64: Float64,
    } %}
      # Returns *self* converted to {{type}}.
      def {{name.id}} : {{type}}
        @decoded.{{name.id}}
      end
    {% end %}
  {% end %}
end
