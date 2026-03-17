#!/bin/bash
set -e

# Show help message
show_help() {
    cat << EOF
Usage: ./script.sh [local] [sign] [upload]

This script builds and deploys a HelloFX iOS application with OpenJDK Mobile.

Arguments:
  local   Use local SDK build (true) or download from releases (false)
          Default: false

  sign    Code sign the app (true/false)
          Default: true

  upload  Upload to App Store Connect (TestFlight) after signing (true/false)
          Default: true

Examples:
  ./script.sh                    # Build with downloaded SDK, sign and upload
  ./script.sh true true false    # Build with local SDK, sign but don't upload
  ./script.sh false false false  # Build with downloaded SDK, without signing and uploading
  ./script.sh true true true     # Build with local SDK, sign and upload

Required Environment Variables:
  JAVA_HOME           Path to JDK 25 or later

  DEVELOPMENT_TEAM    Your Apple Developer Team ID
  CURRENT_VERSION     App version number (e.g., 1.0.0)

  For uploading to App Store:
  API_KEY_ID          Your App Store Connect API Key ID
  ISSUER_ID           Your App Store Connect Issuer ID
  API_PRIVATE_KEY     Your App Store Connect API Private Key content

Prerequisites:
  - macOS (26 to deploy to TestFlight/App Store)
  - Java JDK 25 or later
  - Xcode (26 for macOS 26)
  - xcodegen (install: brew install xcodegen)

For the local SDK build:
  - Run local/script_sdk.sh first to build the SDK

Output:
  build/hellofx                               - HelloFX application
  build/framework                             - iOS framework
  build/HelloFXMobileApp                      - Xcode project
  build/Release/HelloFXMobileApp.xcarchive    - Archive for distribution
  build/Release/Archives/HelloFXMobileApp.ipa - IPA file (if signed and uploaded)

EOF
    exit 0
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

local=${1:-"false"}
sign=${2:-"true"}
upload=${3:-"true"}

root=$PWD
buildPath=$root/build
localPath=$root/local

rm -rf build

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
        echo "Error: JDK version is lower than 25"
        exit
    fi
fi

mkdir build
cd build || exit

if [[ "$local" == false ]]; then
  mkdir jdk
  wget -nv -O jdk/macos-jdk.zip https://github.com/openjdk-mobile/ios-tools/releases/download/snapshot/macos-jdk.zip
  unzip -q jdk/macos-jdk.zip -d jdk
  rm jdk/macos-jdk.zip
  chmod +x jdk/macos-jdk/bin/javac
  chmod +x jdk/macos-jdk/bin/jar
fi

mkdir hellofx
cd hellofx || exit
cp -r "$root/sample/" .
if [[ "$local" == true ]]; then
  "$localPath/sdk/mobile/build/jfx/images/jdk/bin/javac" HelloFX.java
  "$localPath/sdk/mobile/build/jfx/images/jdk/bin/jar" cf HelloFX.jar HelloFX.class openduke.png
else
  ../jdk/macos-jdk/bin/javac HelloFX.java
  ../jdk/macos-jdk/bin/jar cf HelloFX.jar HelloFX.class openduke.png
fi
cd ..

mkdir -p HelloFXMobileApp/HelloFXMobileApp
cp -R ../source/*.* HelloFXMobileApp/HelloFXMobileApp
cp ../project.xml HelloFXMobileApp/project.xml
sed -i '' "s/GET_DEVELOPMENT_TEAM/$DEVELOPMENT_TEAM/g" HelloFXMobileApp/project.xml
sed -i '' "s/GET_CURRENT_VERSION/$CURRENT_VERSION/g" HelloFXMobileApp/project.xml
cp hellofx/HelloFX.jar HelloFXMobileApp/HelloFXMobileApp

mkdir framework
if [[ "$local" == true ]]; then
  cp -R "$localPath/sdk/framework" .
else
  wget -nv -O framework/OpenJDK.xcframework.zip https://github.com/openjdk-mobile/ios-tools/releases/download/snapshot/OpenJDK.xcframework.zip
  unzip -q framework/OpenJDK.xcframework.zip -d framework
  rm framework/OpenJDK.xcframework.zip
fi
cp -R framework/OpenJDK.xcframework HelloFXMobileApp/HelloFXMobileApp

mkdir -p HelloFXMobileApp/HelloFXMobileApp/lib/lib
if [[ "$local" == true ]]; then
  cp "$localPath/sdk/mobile/build/java_bundle/lib/modules" HelloFXMobileApp/HelloFXMobileApp/lib/lib/
  cp "$localPath/sdk/mobile/build/jfx/images/jdk/lib/tzdb.dat" HelloFXMobileApp/HelloFXMobileApp/lib/lib/
else
  mkdir -p lib
  wget -nv -O lib/java_bundle-device.zip https://github.com/openjdk-mobile/ios-tools/releases/download/snapshot/java_bundle-device.zip
  unzip -q lib/java_bundle-device.zip -d lib
  rm lib/java_bundle-device.zip
  cp lib/java_bundle-device/lib/modules HelloFXMobileApp/HelloFXMobileApp/lib/lib/
  cp ./jdk/macos-jdk/lib/tzdb.dat HelloFXMobileApp/HelloFXMobileApp/lib/lib/
fi

xcodegen generate --spec="$buildPath/HelloFXMobileApp/project.xml" --project="$buildPath/HelloFXMobileApp"

echo "Archive project"
cd HelloFXMobileApp || exit
if [[ "$sign" == true ]]; then
  xcodebuild -project HelloFXMobileApp.xcodeproj -scheme HelloFXMobileApp -archivePath "$buildPath/Release/HelloFXMobileApp.xcarchive" -configuration Release -destination 'generic/platform=iOS' archive
else
  xcodebuild CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -project HelloFXMobileApp.xcodeproj -scheme HelloFXMobileApp -archivePath "$buildPath/Release/HelloFXMobileApp.xcarchive" -configuration Debug -destination 'generic/platform=iOS' archive
fi
cd ..

if [[ ! -d "$buildPath/Release/HelloFXMobileApp.xcarchive" ]]; then
    echo "$buildPath/Release/HelloFXMobileApp.xcarchive doesn't exist"
    exit 1
fi
cp "$root/exportOptions.plist" "$buildPath/Release/"
sed -i '' "s/GET_DEVELOPMENT_TEAM/$DEVELOPMENT_TEAM/g" "$buildPath/Release/exportOptions.plist"

final_step() {
    rm -rf "$buildPath/HelloFXMobileApp/private_keys"
}
mkdir -p "$buildPath/HelloFXMobileApp/private_keys"
echo "$API_PRIVATE_KEY" >> "$buildPath/HelloFXMobileApp/private_keys/AuthKey_$API_KEY_ID.p8"
trap final_step EXIT

if [[ "$sign" == true ]] && [[ "$upload" == true ]]; then
  echo "Export and upload ipa"
  xcodebuild -exportArchive -archivePath "$buildPath/Release/HelloFXMobileApp.xcarchive" -exportPath "$buildPath/Release/Archives/HelloFXMobileApp.ipa" -exportOptionsPlist "$buildPath/Release/exportOptions.plist" -authenticationKeyID "$API_KEY_ID" -authenticationKeyIssuerID "$ISSUER_ID" -authenticationKeyPath "$buildPath/HelloFXMobileApp/private_keys/AuthKey_$API_KEY_ID.p8"
fi

cd ../..
