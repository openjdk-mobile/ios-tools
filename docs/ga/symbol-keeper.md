# Referring to native symbols in classlibs

The context of this problem is discussed in https://github.com/openjdk-mobile/ios-tools/issues/27 .
When building the static classlibs in openjdk, we do not create a mapping that would contain the entry points for native functions, called from Java code. 

The JVM resolves these entry points (`Java_*`, `JNI_OnLoad_*`) and the jimage/JDK helpers (`JIMAGE_*`, `JDK_*`) at runtime with `dlsym`.
Since nothing references them at link time, `ld` would not pull their object files out of the static libraries, and the lookups would fail.

When using libraries instead of a framework, the typical solution is to use `-Wl,-force_load` on all the class libraries. This will load all symbols of a library into the resulting executable. 

Instead, and similar to how `make/StaticLibs.gmk` links the static launcher on AIX, which has no whole-archive linker flag, we generate a file while the framework is [built](https://github.com/openjdk-mobile/ios-tools/blob/main/.github/scripts/build-xcframework.sh), 
that references every symbol that needs to be kept in the final executable. It gets compiled into `symbol_keeper.o`, and added to the static library that is used to create the framework.

- It lists, with `nm`, every `Java_*`, `JNI_OnLoad_*`, `JIMAGE_*` and `JDK_*` function defined in the JDK static libraries,
- It generates a CPP file that references all of them, and exposes `load_functions()`,
- It compiles it for the device or simulator, and adds it to `libdevice.a` / `libsim.a`.

Therefore, the file is always up-to-date with the symbols that are in the OpenJDK/Mobile build.

Apps must call `load_functions()` (see [`main.m`](/app/source/main.m)): that reference makes `ld` load `symbol_keeper.o` and, with it, every object file that defines one of those symbols.
The Xcode project uses `STRIP_STYLE: non-global`, to keep the global symbols, given that the JVM resolves the JNI entry points with `dlsym` at runtime.

## TODO:

* How do we (re-)enable building mappings for the classlibs in OpenJDK/mobile (this needs a JBS issue)?

`make/StaticLibsImage.gmk` could take care of generating a file with the symbols to keep per library, using `nm` like in the current script. 
Then the `symbol_keeper` could be generated from those files, instead of using `nm` on the static libraries. 
But the script would need to compile for the device and simulator, and add the object file to `libdevice.a` / `libsim.a` either way.
