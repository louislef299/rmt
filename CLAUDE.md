# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`rmt` is a command-line utility written in Zig for identifying and optionally deleting Emacs backup files (files ending with `~`). The project uses SLRE (Super Light Regular Expression library), a minimal regex engine written in C, accessed through Zig FFI.

## Build System and Commands

This project uses Zig's standard build system. Key commands:

### Development Build
```bash
zig build                    # Build the executable
./zig-out/bin/rmt --help     # Run with help flag
zig build run                # Build and run
zig build run -- [args]     # Build and run with arguments
```

### Testing
```bash
zig build test              # Run unit tests
```

### Release Build
```bash
zig build -Drelease-build   # Build for multiple release targets
```

The release build creates executables for multiple architectures:
- aarch64-macos
- aarch64-linux-gnu/musl  
- x86_64-linux-gnu/musl

## Architecture

### Core Structure
- **Single-file application**: All logic in `src/main.zig`
- **C FFI integration**: Uses SLRE library via `@cImport` and `@cInclude("slre.h")`
- **Minimal dependencies**: Only standard library + SLRE

### Key Components
- **Argument parsing**: Manual string comparison for CLI options
- **File system operations**: Uses `std.fs` for directory iteration and file deletion
- **Pattern matching**: SLRE regex engine for identifying Emacs backup files (`.*~$`)
- **Interactive mode**: User confirmation for deletions

### Build Configuration
- **Version management**: Semantic versioning in `build.zig` (currently 0.0.2)
- **Conditional compilation**: Different build flows for development vs release
- **Cross-platform targets**: Multiple OS/architecture combinations for releases
- **C library linking**: Links with libc for SLRE integration

## File Organization
```
├── src/main.zig           # Main application logic
├── build.zig              # Build configuration and targets
├── build.zig.zon          # Package metadata
├── slre/                  # SLRE regex library (C code)
│   ├── slre.c/.h         # Library implementation
│   └── docs/             # API documentation
└── zig-out/bin/          # Build output directory
```

## Development Notes
- The project has no external Zig dependencies - only uses SLRE C library
- Error handling uses Zig's standard error union pattern
- Memory management uses GeneralPurposeAllocator with proper cleanup
- Cross-platform considerations for Windows (`\r\n` handling in interactive mode)