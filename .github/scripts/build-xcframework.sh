#!/usr/bin/env bash
set -euxo pipefail

# Define constants
LIBFFI=./libffi-ios
LIBFFI_SIM=./libffi-ios-sim
OPENJDK_DEVICE_BUILD=./device
OPENJDK_SIMULATOR_BUILD=./simulator
DEVICE_TARGET=./device-static
SIMULATOR_TARGET=./sim-static
LIBS="libjvm.a libjava.a libzip.a libnet.a libnio.a libjimage.a"

generate_symbols() {
  # extract global, defined symbols
  symbols=$(nm -gU "$@" | awk '$2 == "T" && $3 ~ /^_(Java_|JNI_OnLoad_|JIMAGE_|JDK_)/ {print $3}' | sed 's/^_//' | sort -u)

  if [[ -z "$symbols" ]]; then
    echo "No symbols found in the provided libraries." >&2
    exit 1
  fi

  # create a CPP file that keeps references to all symbols
  symbols_file="symbol_keeper.cpp"
  {
    echo "#include <stdio.h>"
    echo
    # list all symbols as extern void* declarations
    printf "extern void* %s;\n" $symbols
    echo

    # keep a reference to each symbol in an array to prevent dead code elimination
    echo "__attribute__((used))"
    echo "static void* symbol_keeper[] = {"
    printf "  (void*)&%s,\n" $symbols
    echo "};"

    # print the number of symbols kept
    echo "extern \"C\" void load_functions(void) {"
    echo "    static const size_t symbol_keeper_count = sizeof(symbol_keeper) / sizeof(symbol_keeper[0]);"
    out="fprintf(stderr, \"Loaded %zu symbols\\n\", symbol_keeper_count);"
    printf "    %s\n" "$out"
    echo "}"
    echo
  } > "$symbols_file"
}

# Create device static
mkdir $DEVICE_TARGET
cp $LIBFFI/libffi.a $DEVICE_TARGET
cp $OPENJDK_DEVICE_BUILD/images/static-libs/lib/*.a $DEVICE_TARGET
cp $OPENJDK_DEVICE_BUILD/images/static-libs/lib/zero/libjvm.a $DEVICE_TARGET
cd $DEVICE_TARGET

generate_symbols $LIBS
xcrun -sdk iphoneos clang -target arm64-apple-ios15.0 -O2 -c symbol_keeper.cpp -o symbol_keeper.o
libtool -static -no_warning_for_no_symbols -o libdevice.a symbol_keeper.o libffi.a $LIBS
cd ..

# Create sim static
mkdir $SIMULATOR_TARGET
cp $LIBFFI_SIM/libffi.a $SIMULATOR_TARGET
cp $OPENJDK_SIMULATOR_BUILD/images/static-libs/lib/*.a $SIMULATOR_TARGET
cp $OPENJDK_SIMULATOR_BUILD/images/static-libs/lib/zero/libjvm.a $SIMULATOR_TARGET
cd $SIMULATOR_TARGET

generate_symbols $LIBS
xcrun -sdk iphonesimulator clang -target arm64-apple-ios15.0-simulator -O2 -c symbol_keeper.cpp -o symbol_keeper.o
libtool -static -no_warning_for_no_symbols -o libsim.a symbol_keeper.o libffi.a $LIBS
cd ..

# Flatten header location
cp $OPENJDK_DEVICE_BUILD/jdk/include/ios/* $OPENJDK_DEVICE_BUILD/jdk/include/
cp $OPENJDK_SIMULATOR_BUILD/jdk/include/ios/* $OPENJDK_SIMULATOR_BUILD/jdk/include/

# Create XCFramework
xcodebuild -create-xcframework \
  -library $DEVICE_TARGET/libdevice.a \
  -headers $OPENJDK_DEVICE_BUILD/jdk/include \
  -library $SIMULATOR_TARGET/libsim.a \
  -headers $OPENJDK_SIMULATOR_BUILD/jdk/include \
  -output ./OpenJDK.xcframework