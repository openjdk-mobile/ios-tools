# Building mobile app

The [build-app.yml](/.github/workflows/build-app.yml) workflow runs after [Create Framework](xcframework.md) workflow creates the Xcode framework, by creating a new Xcode project that can be used to generate a mobile application that can be run on an iOS device.

The workflow basically runs a [script](../../app/script.sh) that:
- creates a new Xcode project with the initial [sources](../../app/source),
- creates a simple HelloWorld class, that is compiled and added to a jar, that is added to the project as resource,
- adds to the project the OpenJDK mobile build, and the framework, resulting from the [release artifacts](https://github.com/openjdk-mobile/ios-tools/releases/tag/snapshot) published after the combined workflow ends,
- and then uses `xcodebuild` to produce and upload a mobile application that can be downloaded and tested on an iOS device

Since most of the work is delegated to such script, developers can just run the script on their local setup, with their own changes.
