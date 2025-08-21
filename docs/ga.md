# Github Actions

In order to make the components needed to run Java on iOS as reproducible and deterministic as possible, we use a 
number of github actions that build those components based from source code only. In case dependencies are needed,
we build those as well.

The most important components are builds of [OpenJDK/mobile](https://github.com/openjdk/mobile) for iOS (both for
real devices and for simulators). The actions to create these builds are documented [here](ga/opendjk.md).

Building this version of OpenJDK/mobile depends on an implementation of libffi to be available, and we have an action
that does this job, which is documented [here](ga/ffi.md).
