# rmt

`rmt` is a small command-line utility written in [Zig][] for identifying and
optionally deleting Emacs/backup files. This project uses [SLRE][], a minimal
regex engine written in C, accessed leveraging [Zig FFI][].

## Build from Source

```bash
$ zig build && ./zig-out/bin/rmt --help
Usage: rmt [options]

General Options:

  -h, --help          Print command-specific usage
  -i, --interactive   Interactive output
  -r, --recursive     Walk filepath starting at current directory
```

[SLRE]: https://github.com/cesanta/slre
[Zig]: https://ziglang.org/
[Zig FFI]: https://zig.guide/working-with-c/abi
