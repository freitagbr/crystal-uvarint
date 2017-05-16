require "big/big_int"

require "./uvarint/*"

# This module is based on the varint implementation in the Go programming
# language. See: https://golang.org/src/encoding/binary/varint.go

private MSB = 0x80_u8
private REST = 0x7F_u8
private ZERO = 0.to_big_i

# Encodes an Int::Unsigned into a Bytes slice.
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

# Decodes bytes into a BigInt.
private def decode(bytes : Bytes) : BigInt
  x = ZERO
  s = 0
  bytes.each do |b|
    if b < MSB
      return x | (b.to_big_i << s)
    end
    x = x | ((b & REST).to_big_i << s)
    s += 7
  end
  ZERO
end

# Decodes iterable bytes into a BigInt.
private def read_decode(iter : Iterator(UInt8)) : BigInt
  x = ZERO
  s = 0
  iter.each do |b|
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
  @bigint : BigInt

  def initialize(int : Int::Unsigned)
    @bigint = int.to_big_i
    @bytes = encode int
  end

  def initialize(int : BigInt)
    @bigint = int
    @bytes = encode int
  end

  def initialize(bytes : Bytes)
    @bytes = bytes
    @bigint = decode bytes
  end

  def initialize(en : Enumerable(UInt8))
    arr = en.to_a
    bytes = Bytes.new(arr.to_unsafe, arr.size)
    @bytes = bytes
    @bigint = decode bytes
  end

  def initialize(str : String)
    int = str.to_u64 16
    @bigint = int.to_big_i
    @bytes = encode int
  end

  def self.read(str : String)
    iter = str.each_byte
    bigint = read_decode iter
    UVarInt.new bigint
  end

  def self.read(io : IO)
    iter = io.each_byte
    bigint = read_decode iter
    UVarInt.new bigint
  end

  def self.read(iter : Iterator(UInt8))
    bigint = read_decode iter
    UVarInt.new bigint
  end

  def self.parse(str : String)
    # 0123456789abcdef => 01 23 45 67 89 ab cd ef
    iter = str.each_char.in_groups_of(2).map { |e| e.join.to_u8(16) }
    bigint = read_decode iter
    UVarInt.new bigint
  end

  def bytes
    @bytes
  end

  def to_big_i
    @bigint
  end

  def to_s(base : Int32)
    @bigint.to_s base
  end

  def hexstring
    @bytes.hexstring
  end

  macro [](*args)
    %bytes = Bytes[{{*args}}]
    UVarInt.new %bytes
  end

  {% begin %}

    # for the following operators, define a method
    # that performs that mathematical operation on
    # both operands' int values, and returns a new
    # UVarInt with the new value
    {% for op in %w(% & * ** + - / << >> ^) %}
      def {{op.id}}(other : UVarInt) : UVarInt
        UVarInt.new(@bigint {{op.id}} other.to_big_i)
      end
    {% end %}


    # for the following operators, define a method
    # that performs the logical operation on both
    # operands' int values, and returns a boolean value
    {% for op in %w(< <= <=> == > >=) %}
      def {{op.id}}(other : UVarInt)
        @bigint {{op.id}} other.to_big_i
      end
    {% end %}

    # for the following name-type pairs, define a method
    # that is mapped to the method of the same name on
    # the internal BigInt value
    {% for name, type in {
        to_i:   Int32,   to_u:   UInt32,  to_f:   Float64,
        to_i8:  Int8,    to_i16: Int16,   to_i32: Int32,  to_i64: Int64,
        to_u8:  UInt8,   to_u16: UInt16,  to_u32: UInt32, to_u64: UInt64,
        to_f32: Float32, to_f64: Float64,
    } %}
      # Returns *self* converted to {{type}}.
      def {{name.id}} : {{type}}
        @bigint.{{name.id}}
      end
    {% end %}
  {% end %}
end
