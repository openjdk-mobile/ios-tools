# Creating Xcode framework

The [combine-xcframework.yml](/.github/workflows/combine-xcframework.yml) workflow combines the [OpenJDK mobile](openjdk.md) builds into an Xcode framework that can be easily used in Xcode.

The combine workflow:
- triggers the OpenJDK mobile builds for device and simulator
- downloads libffi
- creates a static library
- and then uses xcodebuild to combine the libaries and headers into a framework

The framework itself and the corresponding build of the java.base module are uploaded as a [release artifact](https://github.com/openjdk-mobile/ios-tools/releases/tag/snapshot).
