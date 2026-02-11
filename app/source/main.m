#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#include "jni.h"
#include <stdio.h>

extern void loadfunctions(void);

int main(int argc, char *argv[]) {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:@"output.log"];
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "w+", stdout);

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
    if (res != JNI_OK) {
        fprintf(stderr, "Failed to create JVM\n");
    } else {
        fprintf(stderr, "Created JavaVM\n");
        jclass cls = (*env)->FindClass(env, "HelloWorld");
        if (cls == NULL) {
            fprintf(stderr, "Could not find HelloWorld class\n");
        } else {
            jmethodID mid = (*env)->GetStaticMethodID(env, cls, "main", "([Ljava/lang/String;)V");
            if (mid == NULL) {
                fprintf(stderr, "Could not find main method\n");
            } else {
                fprintf(stderr, "Run main\n");
                (*env)->CallStaticVoidMethod(env, cls, mid, NULL);
                fprintf(stderr, "Done JavaVM\n");
                (*jvm)->DestroyJavaVM(jvm);
            }
        }
    }
    NSString * appDelegateClassName;
    @autoreleasepool {
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}