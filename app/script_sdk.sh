#!/bin/bash
set -e

root=$PWD/sdk
doSim=false

if type -p java; then
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    _java="$JAVA_HOME/bin/java"
else
    echo "no java"
    exit
fi

if [[ "$_java" ]]; then
    version=$(javap -verbose java.lang.String | grep "major version" | cut -d " " -f5)
    if [[ "$version" -lt "69" ]]; then
        echo Error: JDK version is less than 25
        exit
    fi
fi

if [[ ! -d "sdk" ]]; then
  mkdir sdk
fi

cd sdk || exit

if [[ ! -d "libffi" ]]; then
  echo "========== FFI ==========="
  mkdir libffi
  wget -nv -O libffi/libffi-ios.zip https://github.com/openjdk-mobile/ios-tools/releases/download/libffi-build/libffi-ios.zip
  unzip -q libffi/libffi-ios.zip -d libffi
  rm libffi/libffi-ios.zip
fi
if [[ "$doSim" = true ]] && [[ ! -d "libffi-sim" ]]; then
  echo "========== FFI Sim ==========="
  mkdir libffi-sim
  wget -nv -O libffi-sim/libffi-ios-sim.zip https://github.com/openjdk-mobile/ios-tools/releases/download/libffi-build/libffi-ios-sim.zip
  unzip -q libffi-sim/libffi-ios-sim.zip -d libffi-sim
  rm libffi-sim/libffi-ios-sim.zip
fi

if [[ ! -d "openjfx-build" ]]; then
  git clone --depth 1 https://github.com/openjdk-mobile/openjfx-build.git
fi

if [[ ! -d "jfx" ]]; then
  git clone --depth 1 https://github.com/openjdk/jfx.git
  cd jfx || exit
  git apply "$root/../../jfx-patch.diff"
  sh gradlew shadersClasses
  cd ..
fi

if [[ ! -d "mobile" ]]; then
  git clone --depth 1 https://github.com/openjdk/mobile/
  cd mobile || exit
  patch -p1 < ../openjfx-build/openjdk-ext/src/jfx.patch
  git apply "$root/../../lib-patch.diff"
  cd ..
fi

cd mobile || exit
if [[ ! -f "$root/mobile/build/jfx/images/jdk/bin/jmod" ]];  then
  echo "========== macOS SDK with JFX ==========="
  bash configure \
              --with-conf-name=jfx \
              --with-openjfx-modules=../jfx \
              --with-boot-jdk=$JAVA_HOME \
              --disable-warnings-as-errors
  make CONF=jfx images
  ([ $? -eq 0 ] && echo "success!") || (echo "failure!" && exit 1)
fi

if [[ ! -d "$root/mobile/build/ios-aarch64-zero-release/images/static-libs/lib" ]];  then
  echo "========== iOS SDK ==========="
  cp "$root/../../openjdk-ext/src/hotspot/symbol_keeper.cpp" "$root/mobile/src/hotspot/os/bsd"

  bash configure \
      --with-conf-name=ios-aarch64-zero-release \
      --with-openjfx-modules=../jfx \
      --disable-warnings-as-errors \
      --openjdk-target=aarch64-macos-ios \
      --with-sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk \
      --with-libffi-include=$root/libffi/include/ffi \
      --with-libffi-lib=$root/libffi  \
      --with-cups-include="$(xcrun --sdk macosx --show-sdk-path)/usr/include"
  make CONF=ios-aarch64-zero-release javafx.controls-java static-libs-image
  ([ $? -eq 0 ] && echo "success!") || (echo "failure!" && exit 1)
  cp "$root/mobile/build/ios-aarch64-zero-release/jdk/include/ios/jni_md.h" "$root/mobile/build/ios-aarch64-zero-release/jdk/include/"
fi

if [[ "$doSim" = true ]] && [[ ! -d "$root/mobile/build/iossim-aarch64-zero-release/images/static-libs/lib" ]]; then
  echo "========== iOS-Sim SDK ==========="
  bash configure \
      --with-conf-name=iossim-aarch64-zero-release \
      --with-openjfx-modules=../jfx \
      --disable-warnings-as-errors \
      --openjdk-target=aarch64-macos-ios \
      --with-sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
      --with-libffi-include=$root/libffi-sim/include/ffi \
      --with-libffi-lib=$root/libffi-sim  \
      --with-extra-cflags="-target arm64-apple-ios-simulator -mios-simulator-version-min=18.2" \
      --with-extra-cxxflags="-target arm64-apple-ios-simulator -mios-simulator-version-min=18.2" \
      --with-cups-include="$(xcrun --sdk macosx --show-sdk-path)/usr/include"
  make CONF=iossim-aarch64-zero-release static-libs-image javafx.controls-java
  ([ $? -eq 0 ] && echo "success!") || (echo "failure!" && exit 1)
  cp "$root/mobile/build/iossim-aarch64-zero-release/jdk/include/ios/jni_md.h" "$root/mobile/build/iossim-aarch64-zero-release/jdk/include/"
fi
cd ..

echo "========== jmods ==========="
if [[ -d "$root/mobile/build/jmods" ]]; then
  rm -rf "$root/mobile/build/jmods"
fi
mkdir -p "$root/mobile/build/jmods"
module_names=("java.base" "java.desktop" "java.prefs" "java.xml" "java.datatransfer" "javafx.base" "javafx.graphics" "javafx.controls")
for item in "${module_names[@]}"; do
  "$root/mobile/build/jfx/images/jdk/bin/jmod" create --class-path "$root/mobile/build/ios-aarch64-zero-release/jdk/modules/$item" --target-platform ios-aarch64 "$root/mobile/build/jmods/$item.jmod"
done

echo "========== modules ==========="
if [[ -d "$root/mobile/build/java_bundle" ]]; then
   rm -rf "$root/mobile/build/java_bundle"
fi
"$root/mobile/build/jfx/images/jdk/bin/jlink" --module-path "$root/mobile/build/jmods" --add-modules javafx.controls --output "$root/mobile/build/java_bundle"

echo "========== lidDevice.a ==========="
DEVICE_TARGET=./device-static

if [[ ! -d "$DEVICE_TARGET" ]]; then
  mkdir -p $DEVICE_TARGET
fi
cd $DEVICE_TARGET || exit
if [[ -f "$DEVICE_TARGET/libdevice.a" ]]; then
  rm libdevice.a
fi
cp "$root/libffi/libffi.a" .
cp "$root/mobile/build/ios-aarch64-zero-release/images/static-libs/lib"/*.a .
cp "$root/mobile/build/ios-aarch64-zero-release/images/static-libs/lib/zero/libjvm.a" .
libtool -static -o libdevice.a libjvm.a libffi.a libjava.a libzip.a libnet.a libnio.a libjimage.a \
  libglass.a libjavafx_font.a libjavafx_iio.a libprism_common.a libprism_es2.a
cd ..

if [[ "$doSim" = true ]]; then
  echo "========== libsimulator.a ==========="
  SIMULATOR_TARGET=./simulator-static

  if [ ! -d "$SIMULATOR_TARGET" ]; then
    mkdir $SIMULATOR_TARGET
  fi
  cd $SIMULATOR_TARGET || exit
  if [ -f "$SIMULATOR_TARGET/libsimulator.a" ]; then
    rm libsimulator.a
  fi
  cp "$root/libffi-sim/libffi.a" .
  cp "$root/mobile/build/iossim-aarch64-zero-release/images/static-libs/lib"/*.a .
  cp "$root/mobile/build/iossim-aarch64-zero-release/images/static-libs/lib/zero/libjvm.a" .
  libtool -static -o libsimulator.a libjvm.a libffi.a libjava.a libzip.a libnet.a libnio.a libjimage.a \
    libglass.a libjavafx_font.a libjavafx_iio.a libprism_common.a libprism_es2.a
  cd ..
fi

echo "========== Framework ==========="
rm -rf framework
mkdir framework
if [[ "$doSim" = true ]]; then
  xcodebuild -create-xcframework \
    -library $DEVICE_TARGET/libdevice.a \
    -headers $root/mobile/build/ios-aarch64-zero-release/jdk/include \
    -library $SIMULATOR_TARGET/libsimulator.a \
    -headers $root/mobile/build/iossim-aarch64-zero-release/jdk/include \
    -output framework/OpenJDK.xcframework
else
  xcodebuild -create-xcframework \
    -library $DEVICE_TARGET/libdevice.a \
    -headers $root/mobile/build/ios-aarch64-zero-release/jdk/include \
    -output framework/OpenJDK.xcframework
fi

echo "========== Done ==========="

cd ..
