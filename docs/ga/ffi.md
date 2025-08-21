# Building libffi

The action in `build-libffi.yml` builds an implementation of `libffi.a` compiled for iOS.

The bulk of the work is delegated to the `build-libffi-ios.sh` script. We download the sources for libffi-3.5.2
and build the native libffi.a library.
Since there are differences between iOS running on a real iPhone versus running in a simulator, we need to provide
2 different versions of libffi.a 

The artifacts are uploaded, so that they can be used by the openjdk-mobile build actions
