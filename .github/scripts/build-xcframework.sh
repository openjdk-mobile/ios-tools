#!/usr/bin/env bash
set -euxo pipefail

# Create device static
mkdir device-static
cp ./libffi-ios/libffi.a device-static
cp ./device/images/static-libs/lib/*.a device-static
cp ./device/images/static-libs/lib/zero/libjvm.a device-static
cd device-static
libtool -static -o libdevice.a *.a
cd ..

# Create sim static
mkdir sim-static
cp ./libffi-ios-sim/libffi.a sim-static
cp ./simulator/images/static-libs/lib/*.a sim-static
cp ./simulator/images/static-libs/lib/zero/libjvm.a sim-static
cd sim-static
libtool -static -o libsim.a *.a
cd ..

# Flatten header location
cp ./device/jdk/include/ios/* ./device/jdk/include/
cp ./simulator/jdk/include/ios/* ./simulator/jdk/include/

# Create XCFramework
xcodebuild -create-xcframework \
  -library ./device-static/libdevice.a \
  -headers ./device/jdk/include \
  -library ./sim-static/libsim.a \
  -headers ./simulator/jdk/include \
  -output ./OpenJDK.xcframework
zip -r OpenJDK.xcframework.zip OpenJDK.xcframework