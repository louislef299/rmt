# rmt

`rmt` is a small command-line utility written in [Zig][] for identifying and
optionally deleting Emacs backup files. This project uses [SLRE][], a minimal
regex engine written in C, accessed leveraging [Zig FFI][].

## Build from Source

```bash
# Clean zig cache first
$ rm -rf .zig-cache
$ zig build --summary all && ./zig-out/bin/rmt --help
Usage: rmt [options]

General Options:

  -h, --help          Print command-specific usage
  -i, --interactive   Interactive output
  -r, --recursive     Walk filepath starting at current directory
  --version           Print version & build information
```

[SLRE]: https://github.com/cesanta/slre
[Zig]: https://ziglang.org/
[Zig FFI]: https://zig.guide/working-with-c/abi
