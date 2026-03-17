# Building HelloWorld or HelloFX mobile apps locally

While the main focus of this repository is building an end to end streamlined process that produces HelloWorld and HelloFX mobile apps as a result, 
it also allows developers the option to test and modify the Java/JavaFX sources.

For small and quick iterations, pushing such changes and going through the GitHub workflows to generate the apps is cumbersome, so
we have included a [script](/local/script_sdk.sh) that builds all the artifacts locally.

## Build artifacts locally once

With JDK 25, run the script once:

```
cd local
sh script_sdk.sh
cd ..
```

This script does the following steps:
- download `libffi`, 
- clone OpenJDK/OpenJFX and OpenJDK/Mobile repositories
- build the SDK with JavaFX for macOS
- build the Java and JavaFX static libraries for iOS, with debug logs enabled
- create the `modules` file that packages all the Java modules
- create the `OpenJDK.xcframework`

As a result, `/local/sdk` contains all the artifacts needed by the other two scripts used to produce the mobile apps.
In particular, `/local/sdk/mobile` contains the JDK sources and `/local/sdk/jfx` contains the JavaFX sources.

*Note*: to skip the simulator artifacts, run:

```
cd local
sh script_sdk.sh false
cd ..
```

## Build unsigned apps for local testing

Once the local script has successfully ended, you can run the scripts to build HelloWorld and HelloFX apps locally, without signing and skipping the TestFlight upload:

### HelloWorld

```
cd app
sh script.sh true false false
cd ..
```

### HelloFX

```
cd appFX
sh script.sh true false false
cd ..
```

When the scripts end, there are two Xcode projects:
- `/app/build/HelloMobileApp/HelloMobileApp.xcodeproj`
- `app/build/HelloFXMobileApp/HelloFXMobileApp.xcodeproj`

These can be opened with Xcode, do the proper signing for the debug configuration, and deploy and test on an iPhone.

This has the benefits of getting all the logs to the Xcode console, allowing debugging sessions with Xcode or `lldb`, built-in tools like memory or thread usage checks.

## Changing the sources

If changes are needed in the OpenJFX [sources](/local/sdk/jfx), or in the OpenJDK/Mobile [sources](/local/sdk/mobile), 
run the following to update the SDK builds:

```
cd local/mobile
make CONF=ios-aarch64-zero-release LOG=cmdlines,info static-libs-image
cd ..
```
This should take just a couple of seconds.

*Note*: The HelloWorld sample source can be modified [here](/app/sample/HelloWorld.java), and JavaFX sample source can also be modified [here](/appFX/sample/HelloFX.java).

### Update projects 

Then run the scripts again to update the Xcode projects:

```
cd local
sh script_sdk.sh false
cd ..

cd app
sh script.sh true false false
cd ..

cd appFX
sh script.sh true false false
cd ..
```

And test again from Xcode.
