# Creating Xcode framework

The [combine-xcframework.yml](/.github/workflows/combine-xcframework.yml) workflow combines the [OpenJDK mobile](openjdk.md) builds into an Xcode framework that can be easily used in Xcode.

The combine workflow:
- triggers the OpenJDK mobile builds for device and simulator
- downloads libffi
- creates a static library
- and then uses `xcodebuild` to combine the libraries and headers into a framework

Most of the work is delegated to a script, allowing non-CI usage. Developers can just change the constants in the script and run it on their local setup.

The framework itself and the corresponding build of the java.base module are uploaded as a [release artifact](https://github.com/openjdk-mobile/ios-tools/releases/tag/snapshot).
