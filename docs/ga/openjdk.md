# Building openjdk/mobile

There are 2 actions for this, one for building openjdk/mobile for real iPhone devices [build-openjdk.yml](/.github/workflows/build-openjdk.yml), and one for the iPhone simulator [build-openjdk-sim.yml](/.github/workflows/build-openjdk-sim.yml).

In these actions, we clone the head version of https://github.com/openjdk/mobile and build it.
Note that before building, we copy one file from our local openjdk-ext directory:

`cp openjdk-ext/src/hotspot/symbol_keeper.cpp mobile/src/hotspot/os/bsd`

The reason for this is explained [here](../patches/symbol-keeper.md).

This workflow requires a version of `libffi.a` to be available, which explains why we need 
[the libffi action](ffi.md) .

