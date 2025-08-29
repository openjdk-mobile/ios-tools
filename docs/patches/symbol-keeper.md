# Refering to native symbols in classlibs

The context of this problem is discussed in https://github.com/openjdk-mobile/ios-tools/issues/27 .
When building the static classlibs in openjdk, we do not create a mapping that would contain the entry points for native functions, called from Java code. There is some code in OpenJDK that allows for this, so we could probably do that. But even then, we need to integrate the mapping with the xcode framework we build. When using libraries instead of a framework, the typical solution is to use
`-Wl,-force_load` on all the class libraries. This will load all symbols of a library into the resulting executable. 

## TODO:

* how do we (re-)enable building mappings for the classlibs in OpenJDK/mobile (this needs a JBS issue)
* how do we use such a mapping when building an Xcode framework (see https://github.com/openjdk-mobile/ios-tools/blob/main/.github/scripts/build-xcframework.sh) and https://github.com/openjdk-mobile/ios-tools/blob/main/.github/scripts/build-xcframework.sh
