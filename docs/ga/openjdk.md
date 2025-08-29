# Building openjdk/mobile

There are 2 actions for this, one for building openjdk/mobile for real iPhone devices [build-openjdk.yml](/.github/workflows/build-openjdk.yml), and one for the iPhone simulator [build-openjdk-sim.yml](/.github/workflows/build-openjdk-sim.yml).

In these actions, we clone the head version of https://github.com/openjdk/mobile and build it.
This workflow requires a version of `libffi.a` to be available, which explains why we need 
[the libffi action](ffi.md) .

