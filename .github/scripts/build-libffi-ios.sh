#!/usr/bin/env bash
set -euxo pipefail

# Config
LIBFFI_VERSION=3.5.2
OUTPUT_DIR=$(pwd)/build
LIBFFI_SRC=libffi-$LIBFFI_VERSION

# 1. Download sources if missing
if [ ! -d "$LIBFFI_SRC" ]; then
  curl -LO https://github.com/libffi/libffi/releases/download/v$LIBFFI_VERSION/libffi-$LIBFFI_VERSION.tar.gz
  tar xf libffi-$LIBFFI_VERSION.tar.gz
fi

cd $LIBFFI_SRC

python3 generate-darwin-source-and-headers.py --only-ios || true

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# 4. Build for iOS device (arm64)
xcodebuild \
  -project libffi.xcodeproj \
  -scheme libffi-iOS \
  -sdk iphoneos \
  -configuration Release \
  -arch arm64 \
  SYMROOT=$OUTPUT_DIR \
  build

# 5. Build for iOS simulator (x86_64 + arm64-simulator)
xcodebuild \
  -project libffi.xcodeproj \
  -scheme libffi-iOS \
  -sdk iphonesimulator \
  -configuration Release \
  -arch x86_64 \
  SYMROOT=$OUTPUT_DIR \
  build

xcodebuild \
  -project libffi.xcodeproj \
  -scheme libffi-iOS \
  -sdk iphonesimulator \
  -configuration Release \
  -arch arm64 \
  SYMROOT=$OUTPUT_DIR \
  build

echo "All built, now lipo"

# 6. Merge into universal static lib
mkdir -p $OUTPUT_DIR/universal
lipo -create \
  $OUTPUT_DIR/Release-iphoneos/libffi.a \
  $OUTPUT_DIR/Release-iphonesimulator/libffi.a \
  -output $OUTPUT_DIR/universal/libffi.a

echo "✅ Built libffi $LIBFFI_VERSION"
echo "📦 Universal lib: $OUTPUT_DIR/universal/libffi.a"
echo "📂 Headers: $OUTPUT_DIR/Release-iphoneos/include/ffi/"
