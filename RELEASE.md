# Release Process

TODO:

  🎯 Next Steps

  1. Update GitHub URLs in PKGBUILD files with your actual repository
  2. Update maintainer info with your details
  3. Create a release by tagging: git tag v0.0.3 && git push origin v0.0.3
  4. Set up AUR repositories for both package variants
  5. Update checksums from the generated release and publish to AUR

  The setup automatically handles multi-architecture builds (x86_64, ARM64)
  and uses musl-linked binaries for better compatibility across Linux
  distributions.

This document outlines the process for creating releases and publishing to the AUR.

## Creating a Release

1. **Update version numbers**:
   - Update version in `build.zig` (lines 12-16)
   - Update version in `build.zig.zon` (line 13)
   - Update version in `PKGBUILD` files

2. **Create and push a git tag**:
   ```bash
   git tag v0.0.3
   git push origin v0.0.3
   ```

3. **GitHub Actions will automatically**:
   - Build release binaries for all supported platforms
   - Create release archives (.tar.gz files)
   - Generate SHA256 checksums
   - Create a GitHub release with all artifacts

## Publishing to AUR

### Option 1: Binary Package (rmt-bin)

1. **Update checksums in PKGBUILD**:
   - Download the checksums.txt from the GitHub release
   - Update `sha256sums_x86_64` and `sha256sums_aarch64` in `PKGBUILD`

2. **Set up AUR repository**:
   ```bash
   git clone ssh://aur@aur.archlinux.org/rmt-bin.git
   cd rmt-bin
   cp ../rmt-zig/PKGBUILD .
   ./generate-srcinfo.sh  # or makepkg --printsrcinfo > .SRCINFO
   ```

3. **Commit and push to AUR**:
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "Update to v0.0.3"
   git push
   ```

### Option 2: Source Package (rmt-git)

1. **Set up AUR repository**:
   ```bash
   git clone ssh://aur@aur.archlinux.org/rmt-git.git
   cd rmt-git
   cp ../rmt-zig/PKGBUILD-git PKGBUILD
   makepkg --printsrcinfo > .SRCINFO
   ```

2. **Commit and push to AUR**:
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "Update package"
   git push
   ```

## Pre-requisites for AUR Publishing

1. **AUR Account**: Create an account at https://aur.archlinux.org/
2. **SSH Key**: Add your SSH public key to your AUR account
3. **Package Names**: Reserve package names (rmt-bin, rmt-git) on AUR

## Testing Locally

Before publishing to AUR, test the packages locally:

```bash
# Test binary package
cd /tmp
wget https://github.com/yourusername/rmt-zig/releases/download/v0.0.3/rmt-x86_64-linux-musl.tar.gz
# Update PKGBUILD with correct URLs and checksums
makepkg -si

# Test git package  
makepkg -si -p PKGBUILD-git
```

## Files Overview

- `PKGBUILD`: Binary package for AUR (rmt-bin)
- `PKGBUILD-git`: Source package for AUR (rmt-git) 
- `generate-srcinfo.sh`: Helper script to generate .SRCINFO files
- `.github/workflows/ci.yml`: Automated release workflow

## Notes

- The binary package uses musl-linked binaries for better compatibility
- Both x86_64 and aarch64 architectures are supported
- The git package builds from source and includes tests
- Remember to update GitHub URLs and maintainer information in PKGBUILD files