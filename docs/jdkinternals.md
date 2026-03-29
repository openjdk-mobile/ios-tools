# OpenJDK internals

Developing Java applications does not require knowledge about the OpenJDK internals. Porting the Java platform
to new systems is a different thing, though. Developers working on OpenJDK Mobile and related tools should have
at least some understanding of how the JVM works.
In this document, we discuss some of the OpenJDK internals that are relevant for OpenJDK/Mobile developers.

## Running Java code on iOS

Running Java code involves 2 main steps:

1. Create the Java Virtual Machine
2. Invoke a Java method.

## Create the Java Virtual Machine (JVM)

The JVM is created by invoking JNI_CreateJavaVM. In the HelloWorld demo that is explained [here](helloworld.md)
this made done in the `main.c` file:
```
    jint res = JNI_CreateJavaVM(&jvm, (void **)&env, &vm_args);
```
The `JNI_CreateJavaVM` function is defined in [prims/jni.cpp](https://github.com/openjdk/mobile/src/hotspot/share/prims/jni.cpp). 

### Detecting boot modules

Amongst other things, the `JNI_CreateJavaVM` function will invoke `Threads::create_vm`, which is defined in [runtime/threads.cpp](https://github.com/openjdk/mobile/src/hotspot/share/runtime/threads.cpp). 
As part of this function, the system properties are initialized, and the bootclasspath is set.
Inside the `create_vm` function, a call is done to `Arguments::init_system_properties()` which will invoke `os::init_system_properties_values()` which will invoke `os::set_boot_path`, which is defined in [runtime/os.cpp](https://github.com/openjdk/mobile/src/hotspot/share/runtime/os.cpp).
In this function, `Arguments::set_boot_class_path` will be invoked with the detected location of the modules. 
The detection of the modules happens in 2 phases:
1. If there is a file located at `<JAVA_HOME>lib/modules`, that one is considered to be the jimage containing all boot modules.
2. Otherwise, if there is a directory at `<JAVA_HOME>/modules/java.base`, that one is set as the boot_class_path
