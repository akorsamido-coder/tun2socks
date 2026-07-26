#!/bin/bash
# Build script for tun2socks - builds all supported platforms

set -e

BUILD_DIR="build"
BINARY="tun2socks"
MODULE="github.com/xjasonlyu/tun2socks/v2"

# Get version info
BUILD_COMMIT=$(git rev-parse --short HEAD)
BUILD_VERSION=$(git describe --abbrev=0 --tags HEAD 2>/dev/null || echo "dev")

# Build flags
LDFLAGS="-w -s -buildid="
LDFLAGS="$LDFLAGS -X $MODULE/internal/version.Version=$BUILD_VERSION"
LDFLAGS="$LDFLAGS -X $MODULE/internal/version.GitCommit=$BUILD_COMMIT"

# Clean old builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Building tun2socks v$BUILD_VERSION (commit: $BUILD_COMMIT)"
echo "========================================"

# Platform configurations: os:arch[:extra_env]
PLATFORMS=(
  "linux:amd64"
  "linux:arm64"
  "linux:386"
  "linux:armv7:GOARM=7"
  "darwin:amd64"
  "darwin:arm64"
  "freebsd:amd64"
  "openbsd:amd64"
  "windows:amd64"
  "windows:arm64"
)

for platform in "${PLATFORMS[@]}"; do
  IFS=':' read -r os arch extra_env <<< "$platform"
  
  output_name="$BINARY"
  [ "$os" = "windows" ] && output_name="$BINARY.exe"
  
  output_file="$BUILD_DIR/${BINARY}-${os}-${arch}"
  [ "$os" = "windows" ] && output_file="${output_file}.exe"
  
  echo -n "Building $os-$arch... "
  
  env CGO_ENABLED=0 GOOS="$os" GOARCH="$arch" ${extra_env} \
    go build -v -o "$output_file" \
    -ldflags "$LDFLAGS" \
    -tags "" \
    -trimpath 2>/dev/null
  
  if [ -f "$output_file" ]; then
    size=$(du -h "$output_file" | cut -f1)
    echo "✓ ($size)"
  else
    echo "✗ Failed"
  fi
done

echo "========================================"
echo "Build complete! Binaries in: $BUILD_DIR/"
ls -lh "$BUILD_DIR/" || true
