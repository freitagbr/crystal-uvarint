require "spec"
require "../src/uvarint"

describe UVarint do
  it "encodes and decodes random values" do
      (0..100000).each do
        n = Random.rand(0..0x7FFFFFFF).to_u64
        e = UVarint.encode n
        d = UVarint.decode e
        d.should eq(n)
    end
  end

  it "decodes single bytes" do
      n = Random.rand(0..0x7F).to_u8
      buf = [n]
      d = UVarint.decode buf
      d.should eq(n)
  end

  it "decodes multiple bytes" do
      buf = [0xAC_u8, 0x02_u8]
      d = UVarint.decode buf
      d.should eq(300)
  end

  it "decodes multiple bytes with zero" do
      n = Random.rand(0x7F).to_u8
      buf = [0x80_u8, n]
      d = UVarint.decode buf
      d.should eq(n.to_u64 << 7)
  end

  it "encodes to single bytes" do
      n = Random.rand(0x7F).to_u64
      e = UVarint.encode n
      e.should eq([n.to_u8])
  end

  it "encodes to multiple bytes" do
      e = UVarint.encode 300_u64
      e.should eq([0xAC_u8, 0x02_u8])
  end

  it "encodes to multiple bytes with first byte zero" do
      n = 0x0F00_u64
      e = UVarint.encode n
      e.should eq([0x80_u8, 0x1E_u8])
  end

  it "encodes and decodes big integers" do
      bigs = [] of UInt64
      (32..53).each do |i|
          n = (2 ** i).to_u64
          bigs << n - 1
          bigs << n
      end

      bigs.each do |n|
          e = UVarint.encode n
          d = UVarint.decode e
          d.should eq(n)
      end
  end

  it "encodes and decodes really big integers" do
      max_u32 = 0_u32..0xFFFFFFFF_u32
      (0..100000).each do
          upper = Random.rand(max_u32).to_u64 << 32
          lower = Random.rand(max_u32).to_u64
          n = upper + lower
          e = UVarint.encode n
          d = UVarint.decode e
          d.should eq(n)
      end
  end
end
