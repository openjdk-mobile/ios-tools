#!/bin/bash
set -e

local=${1:-"true"}
sign=${2:-"false"}
upload=${3:-"false"}

root=$PWD/build
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
        echo "Error: JDK version is less than 25"
        exit
    fi
fi

mkdir build
cd build || exit

if [[ "$local" == false ]]; then
  mkdir jdk
  wget -nv -O jdk/macos-jdk.zip https://github.com/jperedadnr/ios-tools/releases/download/snapshot/macos-jdk.zip
  unzip -q jdk/macos-jdk.zip -d jdk
  rm jdk/macos-jdk.zip
  chmod +x jdk/macos-jdk/bin/javac
  chmod +x jdk/macos-jdk/bin/jar
fi

mkdir hellofx
cd hellofx || exit
cp -r "$root/../sample/" .
if [[ "$local" == true ]]; then
  "$root/../sdk/mobile/build/jfx/images/jdk/bin/javac" HelloFX.java
  "$root/../sdk/mobile/build/jfx/images/jdk/bin/jar" cf HelloFX.jar HelloFX.class openduke.png
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
  cp -R ../sdk/framework .
else
  wget -nv -O framework/OpenJDK.xcframework.zip https://github.com/jperedadnr/ios-tools/releases/download/snapshot/OpenJDK.xcframework.zip
  unzip -q framework/OpenJDK.xcframework.zip -d framework
  rm framework/OpenJDK.xcframework.zip
fi
cp -R framework/OpenJDK.xcframework HelloFXMobileApp/HelloFXMobileApp

mkdir -p HelloFXMobileApp/HelloFXMobileApp/lib/lib
if [[ "$local" == true ]]; then
  cp ../sdk/mobile/build/java_bundle/lib/modules HelloFXMobileApp/HelloFXMobileApp/lib/lib/
  cp "$root/../sdk/mobile/build/jfx/images/jdk/lib/tzdb.dat" HelloFXMobileApp/HelloFXMobileApp/lib/lib/
else
  mkdir -p lib
  wget -nv -O lib/java_bundle-device.zip https://github.com/jperedadnr/ios-tools/releases/download/snapshot/java_bundle-device.zip
  unzip -q lib/java_bundle-device.zip -d lib
  rm lib/java_bundle-device.zip
  cp lib/java_bundle-device/lib/modules HelloFXMobileApp/HelloFXMobileApp/lib/lib/
  cp ./jdk/macos-jdk/lib/tzdb.dat HelloFXMobileApp/HelloFXMobileApp/lib/lib/
fi

xcodegen generate --spec="$root/HelloFXMobileApp/project.xml" --project="$root/HelloFXMobileApp"

echo "Archive project"
cd HelloFXMobileApp || exit
if [[ "$sign" == true ]]; then
  xcodebuild -project HelloFXMobileApp.xcodeproj -scheme HelloFXMobileApp -archivePath "$root/Release/HelloFXMobileApp.xcarchive" -configuration Release -destination 'generic/platform=iOS' archive
else
  xcodebuild CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -project HelloFXMobileApp.xcodeproj -scheme HelloFXMobileApp -archivePath "$root/Release/HelloFXMobileApp.xcarchive" -configuration Debug -destination 'generic/platform=iOS' archive
fi
if [[ $? != 0 ]]; then
    echo "Xcode build failed"
    exit 1
fi
cd ..

if [[ ! -d "$root/Release/HelloFXMobileApp.xcarchive" ]]; then
    echo "$root/Release/HelloFXMobileApp.xcarchive doesn't exist"
    exit 1
fi
cp "$root/../exportOptions.plist" "$root/Release/"
sed -i '' "s/GET_DEVELOPMENT_TEAM/$DEVELOPMENT_TEAM/g" "$root/Release/exportOptions.plist"

mkdir -p "$root/HelloFXMobileApp/private_keys"
echo "$API_PRIVATE_KEY" >> "$root/HelloFXMobileApp/private_keys/AuthKey_$API_KEY_ID.p8"

if [[ "$upload" == true ]]; then
  echo "Export and upload ipa"
  xcodebuild -exportArchive -archivePath "$root/Release/HelloFXMobileApp.xcarchive" -exportPath "$root/Release/Archives/HelloFXMobileApp.ipa" -exportOptionsPlist "$root/Release/exportOptions.plist" -authenticationKeyID "$API_KEY_ID" -authenticationKeyIssuerID "$ISSUER_ID" -authenticationKeyPath "$root/HelloFXMobileApp/private_keys/AuthKey_$API_KEY_ID.p8"
  if [[ $? != 0 ]]; then
      echo "Xcode build upload failed"
      exit 1
  fi
fi
cd ../..
