# Local Wine Build Notes

The current open runtime was built from the official CodeWeavers CrossOver 23.5
source archive, specifically the bundled Wine source. The installed output is
not committed to this repository.

## Source Inputs

- CrossOver source archive:
  `https://media.codeweavers.com/pub/crossover/source/crossover-sources-23.5.0.tar.gz`
- Local archive path:
  `/home/mars-user/office-open-repro/crossover-sources-23.5.0.tar.gz`
- SHA256:
  `ae9eb42a42be3e4e6d7cfc3fa224d15ec1bf8324742616ed7d5cd708bc8e9ee0`
- Upstream comparison Wine source:
  `https://dl.winehq.org/wine/source/8.0/wine-8.0.1.tar.xz`
- Upstream SHA256:
  `22035f3836b4f9c3b1940ad90f9b9e3c1be09234236d2a80d893180535c75b7d`

## Installed Runtime

- Install prefix: `/home/mars-user/office-open-repro/wine-cx235-install`
- Reported version: `wine-8.0.1`
- Runtime shape: 32-bit i386 Wine build

Useful verification:

```bash
/home/mars-user/office-open-repro/wine-cx235-install/bin/wine --version
file /home/mars-user/office-open-repro/wine-cx235-install/bin/wine
file /home/mars-user/office-open-repro/wine-cx235-install/lib/wine/i386-unix/ntdll.dll.so
```

## Build Commands Used

Configure:

```bash
CC='gcc -m32' CXX='g++ -m32' \
PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig:/usr/share/pkgconfig \
../wine-cx235-office/configure \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --prefix=/home/mars-user/office-open-repro/wine-cx235-install \
  --without-mingw \
  --disable-tests
```

Before building, generated link commands had to be forced to 32-bit:

```bash
perl -0pi -e 's#tools/winebuild/winebuild -w#tools/winebuild/winebuild -m32 -w#g; s#tools/winegcc/winegcc -o#tools/winegcc/winegcc -m32 -o#g' Makefile
find dlls libs -name 'lib*.a' -type f -delete
```

Build and install:

```bash
make -j"$(nproc)" LDFLAGS=-m32
make install LDFLAGS=-m32
```

The local source tree also needed a small generated-header stub for
`programs/winedbg/distversion.h`; see `progress.md` for details.
