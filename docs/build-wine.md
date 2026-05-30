# Local Wine Build Notes

## Current Patched GE-Proton10-34 Runtime

The current non-CrossOver target runtime is:

- Source tree: `/home/mars-user/office-open-repro/valve-wine-ge10-src`
- Valve Wine commit: `1729f00e17e879f98f9df1f2bca86bc5d21a65df`
- Install prefix: `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Version string: `wine-8.0-15655-g1729f00e17`
- Patch: `patches/ge-proton10-34-office-appv-rpc-port.patch`

Both x64 and x86/WOW64 sides were configured with `--without-gstreamer` to
avoid an unrelated system GStreamer header mismatch.

Verification:

```bash
/home/mars-user/office-open-repro/valve-wine-ge10-install/bin/wine --version
/home/mars-user/office-open-repro/valve-wine-ge10-install/bin/wine64 --version
nm /home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine/i386-unix/ntdll.so | grep __wine_rpc_NtReadFile
nm /home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine/x86_64-unix/ntdll.so | grep __wine_rpc_NtReadFile
i686-w64-mingw32-nm /home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine/i386-windows/rpcrt4.dll | grep -i wine_rpc_NtReadFile
x86_64-w64-mingw32-nm /home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine/x86_64-windows/rpcrt4.dll | grep -i wine_rpc_NtReadFile
```

## Earlier CodeWeavers-Source Runtime

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
