require "big/big_int"
require "io"
require "spec"

require "../src/uvarint"

describe UVarInt do
  describe "instantiate" do
    it "handles uint8" do
      v = UVarInt.new 64_u8
      b = v.bytes
      b.should eq(Bytes[64])
    end

    it "handles uint16" do
      v = UVarInt.new 300_u16
      b = v.bytes
      b.should eq(Bytes[172, 2])
    end

    it "handles uint32" do
      v = UVarInt.new 70000_u32
      b = v.bytes
      b.should eq(Bytes[240, 162, 4])
    end

    it "handles uint64" do
      v = UVarInt.new 5000000000_u64
      b = v.bytes
      b.should eq(Bytes[128, 228, 151, 208, 18])
    end

    it "handles bigints" do
      v = UVarInt.new(BigInt.new "9999999999999999999999999999999999")
      b = v.bytes
      b.should eq(Bytes[255, 255, 255, 255, 191, 204, 227, 198, 183, 128, 159, 236, 234, 183, 194, 246, 1])
    end

    it "handles arrays" do
      a = [0xAC_u8, 0x02_u8]
      v = UVarInt.new a
      i = v.to_big_i
      i.should eq(300)
    end

    it "handles deques" do
      d = Deque{0xAC_u8, 0x02_u8}
      v = UVarInt.new d
      i = v.to_big_i
      i.should eq(300)
    end

    it "handles static arrays" do
      s = StaticArray[0xAC_u8, 0x02_u8]
      v = UVarInt.new s
      i = v.to_big_i
      i.should eq(300)
    end

    it "handles tuples" do
      t = {0xAC_u8, 0x02_u8}
      v = UVarInt.new t
      i = v.to_big_i
      i.should eq(300)
    end

    it "handles ranges" do
      r = 0x00_u8..0x09_u8
      v = UVarInt.new r
      i = v.to_big_i
      i.should eq(0)
    end

    it "handles strings" do
      s = "34"
      v = UVarInt.new s
      i = v.to_big_i
      i.should eq(52)
    end
  end

  describe "read" do
    # example multihash, the uvarint is only the first 4 characters.
    # UVarInt.read should stop after reading a complete, valid uvarint.
    #           uvarint
    #            vvvv
    multihash = "b220207d0a1371550f3306532ff44520b649f8be05b72674e46fc24468ff74323ab030"

    it "handles strings" do
      v = UVarInt.read multihash
      h = v.hexstring
      h.should eq("b220")
    end

    it "handles io" do
      # this is messy:
      # treat every two characters as one byte, convert to an array,
      # create a slice from that array,
      # then create an io from that slice
      a = multihash.each_char.in_groups_of(2).map { |e| e.join.to_u8(16) }.to_a
      s = Slice.new(a.size) { |i| a[i] }
      io = IO::Memory.new s
      v = UVarInt.read io
      h = v.hexstring
      h.should eq("b220")
    end

    it "handles byte iterators" do
      i = multihash.each_char.in_groups_of(2).map { |e| e.join.to_u8(16) }
      v = UVarInt.read i
      h = v.hexstring
      h.should eq("b220")
    end
  end

  describe "[] macro" do
    it "instantiates a UVarInt with the passed bytes" do
      v = UVarInt[172, 2]
      b = v.bytes
      b.should eq(Bytes[172, 2])
    end
  end

  describe "decode" do
    it "decodes single bytes" do
      n = Random.rand(0..0x7F).to_u8
      b = Bytes[n]
      v = UVarInt.new b
      i = v.to_big_i
      i.should eq(n)
    end

    it "decodes multiple bytes" do
      b = Bytes[0xAC_u8, 0x02_u8]
      v = UVarInt.new b
      i = v.to_big_i
      i.should eq(300)
    end

    it "decodes multiple bytes with zero" do
      n = Random.rand(0x7F).to_u8
      b = Bytes[0x80_u8, n]
      v = UVarInt.new b
      i = v.to_big_i
      i.should eq(n.to_u64 << 7)
    end
  end

  describe "encode" do
    it "encodes to single bytes" do
      n = Random.rand(0x7F).to_u64
      v = UVarInt.new n
      b = v.bytes
      b.should eq(Bytes[n.to_u8])
    end

    it "encodes to multiple bytes" do
      v = UVarInt.new 300_u64
      b = v.bytes
      b.should eq(Bytes[0xAC_u8, 0x02_u8])
    end

    it "encodes to multiple bytes with first byte zero" do
      v = UVarInt.new 0x0F00_u64
      b = v.bytes
      b.should eq(Bytes[0x80_u8, 0x1E_u8])
    end
  end

  describe "to_s" do
    it "returns self.bigint.to_s" do
      v = UVarInt.new 300_u64
      s = v.to_s 16
      s.should eq("12c")
    end
  end

  describe "hexstring" do
    it "returns self.bytes.hexstring" do
      v = UVarInt.new 300_u64
      h = v.hexstring
      h.should eq("ac02")
    end
  end

  describe "fuzzing" do
    it "encodes and decodes random values" do
      (0..100000).each do
        n = Random.rand(0..0x7FFFFFFF).to_u64
        v = UVarInt.new n
        i = v.to_big_i
        i.should eq(n)
      end
    end

    it "encodes and decodes uint64 values" do
      bigs = [] of UInt64
      (32..53).each do |i|
        n = (2 ** i).to_u64
        bigs << n - 1
        bigs << n
      end

      bigs.each do |n|
        v = UVarInt.new n
        i = v.to_big_i
        i.should eq(n)
      end
    end

    it "encodes and decodes large uint64 values" do
      max_u32 = 0_u32..0xFFFFFFFF_u32
      (0..100000).each do
        upper = Random.rand(max_u32).to_u64 << 32
        lower = Random.rand(max_u32).to_u64
        n = upper + lower
        v = UVarInt.new n
        i = v.to_big_i
        i.should eq(n)
      end
    end
  end

  describe "math operators" do
    it "%" do
      a = UVarInt.new 5_u8
      b = UVarInt.new 2_u8
      c = UVarInt.new 1_u8
      (a % b).should eq(c)
    end

    it "&" do
      a = UVarInt.new 4_u8
      b = UVarInt.new 3_u8
      c = UVarInt.new 0_u8
      (a & b).should eq(c)
    end

    it "*" do
      a = UVarInt.new 4_u8
      b = UVarInt.new 5_u8
      c = UVarInt.new 20_u8
      (a * b).should eq(c)
    end

    it "**" do
      a = UVarInt.new 2_u8
      b = UVarInt.new 4_u8
      c = UVarInt.new 16_u8
      (a ** b).should eq(c)
    end

    it "+" do
      a = UVarInt.new 2_u8
      b = UVarInt.new 4_u8
      c = UVarInt.new 6_u8
      (a + b).should eq(c)
    end

    it "-" do
      a = UVarInt.new 4_u8
      b = UVarInt.new 3_u8
      c = UVarInt.new 1_u8
      (a - b).should eq(c)
    end

    it "/" do
      a = UVarInt.new 8_u8
      b = UVarInt.new 4_u8
      c = UVarInt.new 2_u8
      (a / b).should eq(c)
    end

    it "<<" do
      a = UVarInt.new 2_u8
      b = UVarInt.new 3_u8
      c = UVarInt.new 16_u8
      (a << b).should eq(c)
    end

    it ">>" do
      a = UVarInt.new 16_u8
      b = UVarInt.new 3_u8
      c = UVarInt.new 2_u8
      (a >> b).should eq(c)
    end

    it "^" do
      a = UVarInt.new 4_u8
      b = UVarInt.new 3_u8
      c = UVarInt.new 7_u8
      (a ^ b).should eq(c)
    end
  end

  describe "logic operators" do
    it "<" do
      a = UVarInt.new 1_u8
      b = UVarInt.new 2_u8
      (a < b).should eq(true)
      (b < a).should eq(false)
    end

    it "<=" do
      a = UVarInt.new 1_u8
      b = UVarInt.new 2_u8
      (a <= a).should eq(true)
      (a <= b).should eq(true)
      (b <= a).should eq(false)
    end

    it "<=>" do
      a = UVarInt.new 1_u8
      b = UVarInt.new 2_u8
      (a <=> b).should eq(-1)
      (b <=> a).should eq(1)
      (a <=> a).should eq(0)
    end

    it "==" do
      a = UVarInt.new 1_u8
      b = UVarInt.new 2_u8
      (a == a).should eq(true)
      (a == b).should eq(false)
    end

    it ">" do
      a = UVarInt.new 1_u8
      b = UVarInt.new 2_u8
      (b > a).should eq(true)
      (a > b).should eq(false)
    end

    it ">=" do
      a = UVarInt.new 1_u8
      b = UVarInt.new 2_u8
      (a >= a).should eq(true)
      (b >= a).should eq(true)
      (a >= b).should eq(false)
    end
  end
end
