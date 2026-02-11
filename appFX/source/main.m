#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#include "jni.h"
#include <stdio.h>

extern void loadfunctions(void);
void *launchJava(void *unused);

int main(int argc, char *argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

void* launchJava(void *unused) {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:@"output.log"];
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "w+", stdout);

    JavaVM *jvm;
    JNIEnv *env;
    JavaVMInitArgs vm_args;
    JavaVMOption options[5];
    fprintf(stderr, "starting main\n");
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    
    NSString *classPath = [resourcePath stringByAppendingPathComponent:@"HelloFX.jar"];
    NSString *classPathOption = [NSString stringWithFormat:@"-Djava.class.path=%@", classPath];
    fprintf(stderr, "bcp = %s\n", [classPathOption UTF8String]);
    options[0].optionString = strdup([classPathOption UTF8String]); // Adjust path as needed
    options[1].optionString = strdup([@"--enable-native-access=javafx.graphics" UTF8String]);
    options[2].optionString = strdup([@"-Dos.name=iOS" UTF8String]);
    options[3].optionString = strdup([@"-Djavafx.platform=iOS" UTF8String]);
    options[4].optionString = strdup([@"-Dprism.order=es2" UTF8String]);
    vm_args.version = JNI_VERSION_1_8; // needed to initialize JavaVM
    vm_args.nOptions = 5;
    vm_args.options = options;
    loadfunctions();
    fprintf(stderr, "Create JavaVM\n");
    jint res = JNI_CreateJavaVM(&jvm, (void **)&env, &vm_args);
    if (res != JNI_OK) {
        fprintf(stderr, "Failed to create JVM\n");
    } else {
        fprintf(stderr, "Created JavaVM\n");
        jclass cls = (*env)->FindClass(env, "HelloFX");
        if (cls == NULL) {
            fprintf(stderr, "Could not find HelloFX class\n");
        } else {
            jmethodID mid = (*env)->GetStaticMethodID(env, cls, "main", "([Ljava/lang/String;)V");
            if (mid == NULL) {
                fprintf(stderr, "Could not find main method\n");
            } else {
                fprintf(stderr, "Run main\n");
                (*env)->CallStaticVoidMethod(env, cls, mid, NULL);
                fprintf(stderr, "Done JavaVM\n");
                (*jvm)->DestroyJavaVM(jvm);
                return 0;
            }
        }
    }
    return nil;
}