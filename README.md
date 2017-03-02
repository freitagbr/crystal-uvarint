# crystal-uvarint

`crystal-uvarint` is an
[unsigned varint](https://github.com/multiformats/unsigned-varint)
implementation in Crystal. The implementation is based on
[varint.go](https://golang.org/src/encoding/binary/varint.go).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  uvarint:
    github: freitagbr/crystal-uvarint
```

## Usage

```crystal
require "uvarint"

e = UVarint.encode 300_u64
#=> e == [172_u8, 2_u8]

d = UVarint.decode e
#=> d == 300_u64
```

Use `UVarint.encode` to encode a `UInt64` to a varint, which is an
`Array(UInt8)` (basically, an array of bytes).

Use `UVarint.decode` to decode a varint to a `UInt64`.

## Development

Create an issue or submit a PR. Be sure to add tests if need be.

## Contributing

1. Fork it ( https://github.com/freitagbr/crystal-uvarint/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [freitagbr](https://github.com/freitagbr) Brandon Freitag - creator, maintainer
