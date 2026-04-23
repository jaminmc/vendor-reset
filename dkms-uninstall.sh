#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# More robust regex: works for "vendor-reset/0.1.1, ...", "vendor-reset/a1b2c3d4, ..." or "vendor-reset/0.1.1: broken"
version=$(dkms status vendor-reset | grep -m 1 -oP '(?<=^vendor-reset/)[^:,\s]+')

if [ -z "${version}" ]; then
  echo "vendor-reset is not added to DKMS"
  exit 0
fi

echo "Removing vendor-reset/${version} for ALL kernels..."

dkms remove "vendor-reset/${version}" --all

dir_name="/usr/src/vendor-reset-${version}"
if [ -d "${dir_name}" ]; then
  echo "Removing source directory: ${dir_name}"
  rm -r "${dir_name}"
fi

# Final cleanup of any leftover DKMS metadata (handles broken state)
rm -rf "/var/lib/dkms/vendor-reset" 2>/dev/null || true

echo "vendor-reset has been completely removed from DKMS."
