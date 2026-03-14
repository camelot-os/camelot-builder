# Camelot project builder images

This repository hold the docker images that can be used in order to
build camelot-os projects such as [sample-project](https://github.com/camelot-os/sample-project)

## Building the docker image

This repository do delivers image releases here:
[camelot-builder package](https://github.com/camelot-os/camelot-builder/pkgs/container/camelot-builder)

The SDK image is also published here:
[camelot-builder-sdk package](https://github.com/camelot-os/camelot-builder/pkgs/container/camelot-builder-sdk)

Published image tags are:

- `nightly` on each push to `main`
- the Git tag name when the workflow is triggered by a tag push (for example `v0.1.2`)

Although, if you wish to rebuild the docker image, just run:

```bash
docker build -t camelot-builder:local -f Dockerfile .
docker build -t camelot-builder-sdk:local -f Dockerfile.sdk .
```

You can select a specific SDK release tag when building the SDK image:

```bash
docker build -t camelot-builder-sdk:local -f Dockerfile.sdk --build-arg SDK_RELEASE_TAG=nightly .
```

## camelot-builder-sdk image

This image is made in order to use prebuilt SDK as published in [camelot-sdk releases](https://github.com/camelot-os/camelot-sdk/releases).

This allows to build easily libraries and applications in a standalone mode, using the SDK environment, that
already includes required dependencies such as sentry-kernel UAPI or shield library.

`camelot-builder-sdk` extends `camelot-builder` and installs Camelot SDK nightly tarballs in `/opt/camelot-sdk`:

- `/opt/camelot-sdk/armv7em`
- `/opt/camelot-sdk/armv8m.main`

By default, the image defines:

- `SDK_ROOT=/opt/camelot-sdk/armv8m.main`
- `PKG_CONFIG_PATH=$SDK_ROOT/lib/pkgconfig`

### Using camelot-builder-sdk

Run the image and check default SDK selection:

```bash
docker run -it --rm ghcr.io/camelot-os/camelot-builder-sdk:nightly /bin/bash
echo "$SDK_ROOT"
echo "$PKG_CONFIG_PATH"
pkg-config --cflags uapi
```

For a tagged release image, replace `nightly` with your release tag (for example `v0.1.2`).

Switch to the armv7em SDK in a shell session:

```bash
export SDK_ROOT=/opt/camelot-sdk/armv7em
export PKG_CONFIG_PATH=${SDK_ROOT}/lib/pkgconfig
pkg-config --cflags uapi
```

Or set it directly when starting the container:

```bash
docker run -it --rm \
  -e SDK_ROOT=/opt/camelot-sdk/armv7em \
  -e PKG_CONFIG_PATH=/opt/camelot-sdk/armv7em/lib/pkgconfig \
  ghcr.io/camelot-os/camelot-builder-sdk:nightly /bin/bash
```

## camelot-builder image

Camelot-builder image is made in order to build fully independent projects that do not rely on an
external SDK delivery. This is, for example, the case of the sample-project published in
[sample-project](https://github.com/camelot-os/sample-project).

Building the public sample project can be done with the following commands:

```bash
docker run -it ghcr.io/camelot-os/camelot-builder:nightly /bin/bash
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

```text
root@1035b26a3dfc:/tmp/sample-project# ninja -C output/build
failure here
root@1035b26a3dfc:/tmp/sample-project# ninja -C output/build
[...]
```

The build step should finished in the following way:

```text
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
