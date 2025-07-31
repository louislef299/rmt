# rmt

`rmt` is a small command-line utility written in [Zig][] for identifying and
optionally deleting Emacs backup files. This project uses [SLRE][], a minimal
regex engine written in C, accessed leveraging [Zig FFI][].

## Installation

### Arch Linux (AUR)

```bash
yay -S rmt-bin    # Pre-built binary
# or
yay -S rmt-git    # Build from source
```

### Build from Source

```bash
$ zig build && ./zig-out/bin/rmt --help
Usage: rmt [options]

General Options:

  -h, --help          Print command-specific usage
  -i, --interactive   Interactive output
  -r, --recursive     Walk filepath starting at current directory
  --version           Print version & build information
```

### Other Platforms

Download pre-built binaries from [releases][] or build from source using Zig
0.14+.

[releases]: https://github.com/yourusername/rmt-zig/releases
[SLRE]: https://github.com/cesanta/slre
[Zig]: https://ziglang.org/
[Zig FFI]: https://zig.guide/working-with-c/abi
