#!/bin/bash
# Script to generate .SRCINFO files for AUR packages

echo "Generating .SRCINFO files for AUR packages..."

# Generate .SRCINFO for binary package
if [ -f PKGBUILD ]; then
    echo "Generating .SRCINFO for rmt-bin..."
    makepkg --printsrcinfo > .SRCINFO-bin
    echo "Generated .SRCINFO-bin"
fi

# Generate .SRCINFO for git package
if [ -f PKGBUILD-git ]; then
    echo "Generating .SRCINFO for rmt-git..."
    cp PKGBUILD-git PKGBUILD-temp
    makepkg --printsrcinfo -p PKGBUILD-temp > .SRCINFO-git
    rm PKGBUILD-temp
    echo "Generated .SRCINFO-git"
fi

echo "Done! Remember to:"
echo "1. Update the GitHub URLs in PKGBUILD files with your actual repository"
echo "2. Update maintainer information"
echo "3. Update checksums after creating a release"
echo "4. Copy the appropriate files to separate AUR repositories"