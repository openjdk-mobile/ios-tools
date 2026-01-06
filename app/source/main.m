#import <Foundation/Foundation.h>
#include "jni.h"
#include <stdio.h>
extern void loadfunctions();
int main(int argc, char *argv[]) {
    JavaVM *jvm;
    JNIEnv *env;
    JavaVMInitArgs vm_args;
    JavaVMOption options[2];
    fprintf(stderr, "starting main\n");
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    
    NSString *classPath = [resourcePath stringByAppendingPathComponent:@"HelloWorld.jar"];
    NSString *classPathOption = [NSString stringWithFormat:@"-Djava.class.path=%@", classPath];
    fprintf(stderr, "bcp = %s\n", [classPathOption UTF8String]);
    options[0].optionString = strdup([classPathOption UTF8String]); // Adjust path as needed
    vm_args.version = JNI_VERSION_1_8; // needed to initialize JavaVM
    vm_args.nOptions = 1;
    vm_args.options = options;
    loadfunctions();
    fprintf(stderr, "Create JavaVM\n");
    jint res = JNI_CreateJavaVM(&jvm, (void **)&env, &vm_args);
    fprintf(stderr, "Created JavaVM\n");
    if (res != JNI_OK) {
        printf("Failed to create JVM\n");
        return 1;
    }
    jclass cls = (*env)->FindClass(env, "HelloWorld");
    if (cls == NULL) {
        printf("Could not find HelloWorld class\n");
        return 1;
    }
    jmethodID mid = (*env)->GetStaticMethodID(env, cls, "main", "([Ljava/lang/String;)V");
    if (mid == NULL) {
        printf("Could not find main method\n");
        return 1;
    }
    (*env)->CallStaticVoidMethod(env, cls, mid, NULL);
    (*jvm)->DestroyJavaVM(jvm);
    return 0;
}