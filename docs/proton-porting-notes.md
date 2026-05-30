# Proton porting notes

Current target: `GE-Proton10-34`

Local install:

- Runtime path: `/home/mars-user/.local/share/office-proton/GE-Proton10-34`
- Version file: `1774238111 GE-Proton10-34`
- Release: `https://github.com/GloriousEggroll/proton-ge-custom/releases/tag/GE-Proton10-34`
- Source tag tarball: `https://api.github.com/repos/GloriousEggroll/proton-ge-custom/tarball/GE-Proton10-34`
- `wine` submodule at that tag: `ValveSoftware/wine@1729f00e17e879f98f9df1f2bca86bc5d21a65df`
- `wine-staging` submodule at that tag: `wine-staging/wine-staging@05bc4b822fdb1898777b08a8597639ad851f5601`

## Confirmed missing patch

The working CodeWeavers-source Wine 8.0.1 runtime exports:

```text
00022530 T __wine_rpc_NtReadFile
```

from:

```text
/home/mars-user/office-open-repro/wine-cx235-install/lib/wine/i386-unix/ntdll.so
```

The installed GE-Proton10-34 runtime has no matching symbol in:

```text
/home/mars-user/.local/share/office-proton/GE-Proton10-34/files/lib/wine/i386-unix/ntdll.so
```

The GE-Proton10-34 source `wine` submodule also lacks the patch:

- `dlls/rpcrt4/rpc_transport.c` still calls `NtReadFile(connection->pipe, ...)`.
- `dlls/ntdll/unix/file.c` has no `__wine_rpc_NtReadFile` implementation.

This lines up with the current GE-Proton10 WOW64 blocker:

```text
AppVISVAPIError ... swrpcserver.cpp : 248 ... 0x6d3
30175-4 (1747)
```

## Patch artifact added

`patches/crossover-235-office-appv-rpc-wine801.patch` contains the narrow
CrossOver 23.5 / Wine 8.0.1 `CXHACK 14391` slice:

- `dlls/rpcrt4/rpc_transport.c`: route named-pipe RPC reads through
  `__wine_rpc_NtReadFile`.
- `dlls/ntdll/unix/file.c`: add `__wine_rpc_NtReadFile`.
- `dlls/ntdll/ntdll.spec`: export/register the syscall.
- `dlls/ntdll/unix/loader.c`: add it to the syscall table.
- `dlls/wow64/file.c` and `dlls/wow64/syscall.h`: add WOW64 dispatch glue.

Dry-run status:

```text
patch --dry-run -d /home/mars-user/office-open-repro/upstream/wine-8.0.1 -p1 \
  < /home/mars-user/excel-on-linux/patches/crossover-235-office-appv-rpc-wine801.patch
```

passes against upstream Wine 8.0.1, with small line offsets only.

`patches/ge-proton10-34-office-appv-rpc-port.patch` is the same idea ported to
the exact GE-Proton10-34 `wine` submodule commit:

```text
ValveSoftware/wine@1729f00e17e879f98f9df1f2bca86bc5d21a65df
```

Porting note: newer Wine generates the ntdll syscall tables from
`ntdll.spec`, so this patch does not carry over the old Wine 8.0.1 generated
`dlls/wow64/syscall.h` edit. It does still need a small
`dlls/ntdll/unix/loader.c` declaration for the generated syscall table to
compile cleanly. The port changes:

- `dlls/rpcrt4/rpc_transport.c`
- `dlls/ntdll/unix/file.c`
- `dlls/ntdll/unix/loader.c`
- `dlls/ntdll/ntdll.spec`
- `dlls/wow64/file.c`

Local sparse checkout used for the port:

```text
/home/mars-user/office-open-repro/valve-wine-ge10-src
```

Validation run:

```text
git -C /home/mars-user/office-open-repro/valve-wine-ge10-src diff --check
git -C /home/mars-user/office-open-repro/valve-wine-ge10-src apply --check --reverse \
  /home/mars-user/excel-on-linux/patches/ge-proton10-34-office-appv-rpc-port.patch
```

## Next Proton step

The patched 64-bit Wine side now builds and installs to:

```text
/home/mars-user/office-open-repro/valve-wine-ge10-install
```

Build notes:

- `dlls/ntdll/unix/loader.c` needed
  `extern typeof(NtReadFile) __wine_rpc_NtReadFile;`.
- The local Ubuntu GStreamer headers did not match GE-Proton10-34's
  `winegstreamer/media-converter` code, so the x64 build was configured with
  `--without-gstreamer`.
- `libsdl2-dev` was needed before `winebus.sys` linked cleanly.
- Verified installed symbols:
  `ntdll.so` contains local `__wine_rpc_NtReadFile`, and `rpcrt4.dll` imports
  and exports `__wine_rpc_NtReadFile`.

Next, build/install the matching 32-bit side for WOW64, then rerun the existing
GE-Proton10 WOW64 Office install. The expected test is that the ODT pass moves
beyond the current AppV/C2R RPC `0x6d3` failure.
