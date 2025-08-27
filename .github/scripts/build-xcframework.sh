#!/usr/bin/env bash
set -euxo pipefail

# Define constants
LIBFFI=./libffi-ios
LIBFFI_SIM=./libffi-ios-sim
DEVICE_SRC=./device
SIMULATOR_SRC=./simulator
DEVICE_TARGET=./device-static
SIMULATOR_TARGET=./sim-static

# Create device static
mkdir $DEVICE_TARGET
cp $LIBFFI/libffi.a $DEVICE_TARGET
cp $DEVICE_SRC/images/static-libs/lib/*.a $DEVICE_TARGET
cp $DEVICE_SRC/images/static-libs/lib/zero/libjvm.a $DEVICE_TARGET
cd $DEVICE_TARGET
libtool -static -o libdevice.a *.a
cd ..

# Create sim static
mkdir $SIMULATOR_TARGET
cp $LIBFFI_SIM/libffi.a $SIMULATOR_TARGET
cp $SIMULATOR_SRC/images/static-libs/lib/*.a $SIMULATOR_TARGET
cp $SIMULATOR_SRC/images/static-libs/lib/zero/libjvm.a $SIMULATOR_TARGET
cd $SIMULATOR_TARGET
libtool -static -o libsim.a *.a
cd ..

# Flatten header location
cp $DEVICE_SRC/jdk/include/ios/* $DEVICE_SRC/jdk/include/
cp $SIMULATOR_SRC/jdk/include/ios/* $SIMULATOR_SRC/jdk/include/

# Create XCFramework
xcodebuild -create-xcframework \
  -library $DEVICE_TARGET/libdevice.a \
  -headers $DEVICE_SRC/jdk/include \
  -library $SIMULATOR_TARGET/libsim.a \
  -headers $SIMULATOR_SRC/jdk/include \
  -output ./OpenJDK.xcframework
zip -r OpenJDK.xcframework.zip OpenJDK.xcframework