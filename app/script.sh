#!/bin/bash

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
    if [[ "$version" < "69" ]]; then
        echo Error: JDK version is less than 25
        exit
    fi
fi

mkdir build
cd build

mkdir helloworld
cd helloworld
echo \
'public class HelloWorld {

    public static void main(String[] args) {
        System.out.println("Hey, Hello World!!");
    }
}
' > HelloWorld.java
javac HelloWorld.java
jar cf HelloWorld.jar HelloWorld.class
cd ..

mkdir -p HelloMobileApp/HelloMobileApp
cp -R ../source/*.* HelloMobileApp/HelloMobileApp
cp ../project.xml HelloMobileApp/project.xml
sed -i '' "s/GET_DEVELOPMENT_TEAM/$DEVELOPMENT_TEAM/g" HelloMobileApp/project.xml
cp helloworld/HelloWorld.jar HelloMobileApp/HelloMobileApp

mkdir framework
wget -nv -O framework/OpenJDK.xcframework.zip https://github.com/openjdk-mobile/ios-tools/releases/download/snapshot/OpenJDK.xcframework.zip
unzip -q framework/OpenJDK.xcframework.zip -d framework
rm framework/OpenJDK.xcframework.zip
cp -R framework/OpenJDK.xcframework HelloMobileApp/HelloMobileApp

mkdir -p lib/modules
wget -nv -O lib/java.base-device.zip https://github.com/openjdk-mobile/ios-tools/releases/download/snapshot/java.base-device.zip
unzip -q lib/java.base-device.zip -d lib/modules
rm lib/java.base-device.zip
cp -R lib HelloMobileApp/HelloMobileApp

xcodegen generate --spec=$root/HelloMobileApp/project.xml --project=$root/HelloMobileApp

cd HelloMobileApp
xcodebuild CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DSTROOT=$root/Release archive
cd ..
