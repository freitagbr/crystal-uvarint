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

    it "handles arrays" do
      a = [0xAC_u8, 0x02_u8]
      v = UVarInt.new a
      u = v.uint
      u.should eq(300)
    end

    it "handles deques" do
      d = Deque{0xAC_u8, 0x02_u8}
      v = UVarInt.new d
      u = v.uint
      u.should eq(300)
    end

    it "handles static arrays" do
      s = StaticArray[0xAC_u8, 0x02_u8]
      v = UVarInt.new s
      u = v.uint
      u.should eq(300)
    end

    it "handles tuples" do
      t = {0xAC_u8, 0x02_u8}
      v = UVarInt.new t
      u = v.uint
      u.should eq(300)
    end

    it "handles ranges" do
      r = 0x00_u8..0x09_u8
      v = UVarInt.new r
      u = v.uint
      u.should eq(0)
    end

    it "handles strings" do
      s = "abcd"
      v = UVarInt.new s
      u = v.uint
      u.should eq(97)
    end

    it "raises an exception if passed more than 10 bytes" do
      b = Array.new(20, 0_u8)
      ex = expect_raises(ArgumentError) { UVarInt.new b }
      ex.message.should eq("cannot initialize with more than 10 bytes")
    end
  end

  describe "[] macro" do
    it "throws if more than 10 bytes are passed" do
      ex = expect_raises(ArgumentError) { UVarInt[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] }
      ex.message.should eq("cannot initialize with more than 10 bytes")
    end

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
      u = v.uint
      u.should eq(n)
    end

    it "decodes multiple bytes" do
      b = Bytes[0xAC_u8, 0x02_u8]
      v = UVarInt.new b
      u = v.uint
      u.should eq(300)
    end

    it "decodes multiple bytes with zero" do
      n = Random.rand(0x7F).to_u8
      b = Bytes[0x80_u8, n]
      v = UVarInt.new b
      u = v.uint
      u.should eq(n.to_u64 << 7)
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
    it "returns self.uint.to_s" do
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
        u = v.uint
        u.should eq(n)
      end
    end

    it "encodes and decodes big integers" do
      bigs = [] of UInt64
      (32..53).each do |i|
        n = (2 ** i).to_u64
        bigs << n - 1
        bigs << n
      end

      bigs.each do |n|
        v = UVarInt.new n
        u = v.uint
        u.should eq(n)
      end
    end

    it "encodes and decodes really big integers" do
      max_u32 = 0_u32..0xFFFFFFFF_u32
      (0..100000).each do
        upper = Random.rand(max_u32).to_u64 << 32
        lower = Random.rand(max_u32).to_u64
        n = upper + lower
        v = UVarInt.new n
        u = v.uint
        u.should eq(n)
      end
    end
  end
end
