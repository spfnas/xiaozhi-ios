#!/bin/sh
# 下载并编译 libopus 静态库 (作为 iOS 依赖)
# 在 Xcode Build Phase / GitHub Actions 中调用
set -e

OPUS_VERSION="${OPUS_VERSION:-1.5.2}"
SRCROOT="${SRCROOT:-$(cd "$(dirname "$0")" && pwd)}"
OPUS_DIR="$SRCROOT/opus"
BUILD_DIR="$OPUS_DIR/build"

if [ -f "$OPUS_DIR/lib/libopus.a" ]; then
  echo "opus already built, skip"
  exit 0
fi

mkdir -p "$OPUS_DIR"
cd "$OPUS_DIR"

if [ ! -d "opus-$OPUS_VERSION" ]; then
  echo "downloading opus $OPUS_VERSION"
  curl -fSL "https://downloads.xiph.org/releases/opus/opus-$OPUS_VERSION.tar.gz" -o opus.tar.gz
  tar xzf opus.tar.gz
  rm opus.tar.gz
fi

cd "opus-$OPUS_VERSION"

# 交叉编译到 iOS (arm64 / arm64-simulator)
export CC="$(xcrun -f clang)"
export SDK_ROOT="$(xcrun -sdk iphoneos --show-sdk-path)"
export CFLAGS="-arch arm64 -isysroot $SDK_ROOT -miphoneos-version-min=15.0 -fembed-bitcode"
./configure --host=aarch64-apple-darwin --disable-shared --enable-static --disable-doc --disable-extra-programs --prefix="$BUILD_DIR"
make -j"$(sysctl -n hw.ncpu)"
make install

# 合并到固定路径
mkdir -p "$OPUS_DIR/lib" "$OPUS_DIR/include"
cp "$BUILD_DIR/lib/libopus.a" "$OPUS_DIR/lib/libopus.a"
cp -R "$BUILD_DIR/include/opus" "$OPUS_DIR/include/opus" 2>/dev/null || cp -R "$BUILD_DIR/include/"* "$OPUS_DIR/include/"
echo "opus build done -> $OPUS_DIR/lib/libopus.a"
