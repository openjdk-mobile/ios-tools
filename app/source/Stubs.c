#include <stdio.h>
// These functions are referenced by the JVM symbol keeper but are missing
// from the ios build. We provide empty stubs to satisfy the linker.
// Stub for Java_java_io_Console_istty
// Usually returns a boolean (jboolean), returning 0 (false) is safe.
int Java_java_io_Console_istty() {
    return 0;
}
// Stub for Java_sun_nio_fs_MacOSXNativeDispatcher_normalizepath
// This is likely expected to return a String or similar, but for a
// Hello World on ios, it is unlikely to be called.
void* Java_sun_nio_fs_MacOSXNativeDispatcher_normalizepath() {
    return NULL;
}
