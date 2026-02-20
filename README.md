# Camelot project builder image

This repository hold the docker image that can be used in order to
build camelot-os projects such as https://github.com/camelot-os/sample-project

## Building the docker image

This repository do delivers image releases here https://github.com/camelot-os/camelot-builder/pkgs/container/camelot-builder

Although, if you wish to rebuild the docker image, just run:

```
docker build -t imagename .
```

## cloning and building Camelot-OS projects in the image

Building the public sample project can be done with the following commands:

```
docker run -it ghcr.io/camelot-os/camelot-builder:latest /bin/bash
root@1035b26a3dfc:/tmp# git clone https://github.com/camelot-os/sample-project
Cloning into 'sample-project'...
[...]
root@1035b26a3dfc:/tmp# cd sample-project
root@1035b26a3dfc:/tmp/sample-project# barbican download && barbican setup
[...]
```

Now you need to build the project

> [!WARNING]
> by now, the first ninja attempt fails, and thus needs to be called twice

```
root@1035b26a3dfc:/tmp/sample-project# ninja -C output/build
failure here
root@1035b26a3dfc:/tmp/sample-project# ninja -C output/build
[...]
```

The build step should finished in the following way:

```
[15/28] sample_c_app: linking /tmp/sample-project/output/build/camelot_private/sample-c-app.dummy.elf
[16/28] generating firmware memory layout
[17/28] generating hello linker script
[18/28] generating sample-c-app linker script
[19/28] hello: linking /tmp/sample-project/output/build/camelot_private/hello.elf
[20/28] sample_c_app: linking /tmp/sample-project/output/build/camelot_private/sample-c-app.elf
[21/28] generate task hello metadata
[22/28] generate task sample-c-app metadata
[23/28] objcopy /tmp/sample-project/output/build/camelot_...tmp/sample-project/output/build/camelot_private/hello.hex
[24/28] kernel task metadata fixup
[25/28] objcopy /tmp/sample-project/output/build/camelot_...ple-project/output/build/camelot_private/sample-c-app.hex
[26/28] objcopy /tmp/sample-project/output/build/camelot_...le-project/output/build/camelot_private/sentry-kernel.hex
[27/28] generating /tmp/sample-project/output/build/firmware.hex with srec_cat
```
