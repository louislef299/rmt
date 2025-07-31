# AUR Packages

This directory contains files for publishing `rmt` to the Arch User Repository.

## Package Options

- **rmt-bin**: Pre-built binary package (faster installation)
- **rmt-git**: Source package that builds from git (includes tests)

## Files

- `PKGBUILD` - Binary package configuration
- `PKGBUILD-git` - Git package configuration  
- `generate-srcinfo.sh` - Helper script to generate .SRCINFO files

## Publishing Steps

1. **Update maintainer info** in PKGBUILD files
2. **Update GitHub URLs** with actual repository
3. **Generate .SRCINFO files**: `./generate-srcinfo.sh`
4. **Update checksums** after creating a release
5. **Submit to AUR**:
   ```bash
   git clone ssh://aur@aur.archlinux.org/rmt-bin.git
   cd rmt-bin
   cp ../PKGBUILD .
   makepkg --printsrcinfo > .SRCINFO
   git add PKGBUILD .SRCINFO
   git commit -m "Initial import"
   git push
   ```

## Testing Locally

```bash
makepkg -si          # Test binary package
makepkg -si -p PKGBUILD-git  # Test git package
```