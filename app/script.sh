#!/bin/bash
set -e

local=${1:-"true"}
sign=${2:-"false"}
upload=${3:-"false"}

root=$PWD/build
localPath=$PWD/../local

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
        echo Error: JDK version is lower than 25
        exit
    fi
fi

mkdir build
cd build || exit

mkdir helloworld
cd helloworld || exit
cp -r "$root/../sample/" .
javac HelloWorld.java
jar cf HelloWorld.jar HelloWorld.class
cd ..

mkdir -p HelloMobileApp/HelloMobileApp
cp -R ../source/*.* HelloMobileApp/HelloMobileApp
cp ../project.xml HelloMobileApp/project.xml
sed -i '' "s/GET_DEVELOPMENT_TEAM/$DEVELOPMENT_TEAM/g" HelloMobileApp/project.xml
sed -i '' "s/GET_CURRENT_VERSION/$CURRENT_VERSION/g" HelloMobileApp/project.xml
cp helloworld/HelloWorld.jar HelloMobileApp/HelloMobileApp

mkdir framework
if [[ "$local" == true ]]; then
  cp -R "$localPath/sdk/framework" .
else
  wget -nv -O framework/OpenJDK.xcframework.zip https://github.com/openjdk-mobile/ios-tools/releases/download/snapshot/OpenJDK.xcframework.zip
  unzip -q framework/OpenJDK.xcframework.zip -d framework
  rm framework/OpenJDK.xcframework.zip
fi
cp -R framework/OpenJDK.xcframework HelloMobileApp/HelloMobileApp

mkdir -p HelloMobileApp/HelloMobileApp/lib/lib
if [[ "$local" == true ]]; then
  cp "$localPath/sdk/mobile/build/java_bundle/lib/modules" HelloMobileApp/HelloMobileApp/lib/lib/
else
  mkdir -p lib
  wget -nv -O lib/java_bundle-device.zip https://github.com/openjdk-mobile/ios-tools/releases/download/snapshot/java_bundle-device.zip
  unzip -q lib/java_bundle-device.zip -d lib
  rm lib/java_bundle-device.zip
  cp lib/java_bundle-device/lib/modules HelloMobileApp/HelloMobileApp/lib/lib/
fi

xcodegen generate --spec="$root/HelloMobileApp/project.xml" --project="$root/HelloMobileApp"

echo "Archive project"
cd HelloMobileApp || exit
if [[ "$sign" == true ]]; then
  xcodebuild -project HelloMobileApp.xcodeproj -scheme HelloMobileApp -archivePath "$root/Release/HelloMobileApp.xcarchive" -configuration Release -destination 'generic/platform=iOS' archive
else
  xcodebuild CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -project HelloMobileApp.xcodeproj -scheme HelloMobileApp -archivePath "$root/Release/HelloMobileApp.xcarchive" -configuration Debug -destination 'generic/platform=iOS' archive
fi

if [[ ! -d "$root/Release/HelloMobileApp.xcarchive" ]]; then
    echo "$root/Release/HelloMobileApp.xcarchive doesn't exist"
    exit 1
fi
cp "$root/../exportOptions.plist" "$root/Release/"
sed -i '' "s/GET_DEVELOPMENT_TEAM/$DEVELOPMENT_TEAM/g" "$root/Release/exportOptions.plist"

final_step() {
    rm -rf "$root/HelloMobileApp/private_keys"
}
mkdir -p "$root/HelloMobileApp/private_keys"
echo "$API_PRIVATE_KEY" >> "$root/HelloMobileApp/private_keys/AuthKey_$API_KEY_ID.p8"
trap final_step EXIT

if [[ "$sign" == true ]] && [[ "$upload" == true ]]; then
  echo "Export and upload ipa"
  xcodebuild -exportArchive -archivePath "$root/Release/HelloMobileApp.xcarchive" -exportPath "$root/Release/Archives/HelloMobileApp.ipa" -exportOptionsPlist "$root/Release/exportOptions.plist" -authenticationKeyID "$API_KEY_ID" -authenticationKeyIssuerID "$ISSUER_ID" -authenticationKeyPath "$root/HelloMobileApp/private_keys/AuthKey_$API_KEY_ID.p8"
fi

cd ../..
