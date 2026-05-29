# Office-on-Wine open reproduction notes

Goal: replace the working CrossOver 23.5 Excel path with an open Wine/Proton script.

## Current known-good baseline

- Working app: Excel from Office Click-to-Run.
- Current working clean prefix:
  `/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides`
- Current working runtime:
  `/home/mars-user/office-open-repro/wine-cx235-install`
- Prefix type: Windows 7, `win32`
- CrossOver public version: `23.5.0`
- CrossOver Wine fingerprint from `ntdll.so`: `wine-8.0.1-8785-g8b757459cdb`
- Office installer path that succeeded:
  `/home/mars-user/office-odt/old-12624/setup.exe /configure /home/mars-user/office-odt/install-office32-2002-excelonly.xml`
- Visual proof:
  `/home/mars-user/office-open-repro-clean-overrides-excel-signin.png`

Earlier CrossOver fallback:

- Working bottle: `/home/mars-user/.cxoffice235/office365-cx235-win7c`
- Working launcher: `/home/mars-user/.local/bin/excel-crossover235`
- Working CrossOver install: `/home/mars-user/crossover-23.5`
- Visual proof: `/home/mars-user/office-final-verify.png`

## Pinned Office inputs

- Original bootstrapper: `/home/mars-user/OfficeSetup.exe`
  - sha256: `1dd6491f068d450cd686b31e4574da540ad8948bdf1cebbc7feba215fe2c7d2c`
- Archived Office Deployment Tool: `/home/mars-user/office-odt/old-officedeploymenttool_12624-20320.exe`
  - sha256: `ae1cfca801d21559032ecc5f44912b17735d85a8a568258e1a717a14c7738973`
- Extracted archived ODT setup: `/home/mars-user/office-odt/old-12624/setup.exe`
  - sha256: `0e6334e743a0c9d2280d37518026e21a63f937d0506cf5fca6592068e5266699`
- Working install XML: `/home/mars-user/office-odt/install-office32-2002-excelonly.xml`
  - sha256: `4fc8f7a34dc50ddd9d3e729dc394b4453a6450ef2be45cecaf76268a9811fdf4`
- Office payload cache: `/home/mars-user/office-cache32-2002`
  - version: `16.0.12527.21416`
  - channel: `SemiAnnual`
  - edition: 32-bit
  - product: `O365HomePremRetail`
  - app set: Excel only, most other Office apps excluded

## CrossOver source archive

- Official source archive: `https://media.codeweavers.com/pub/crossover/source/crossover-sources-23.5.0.tar.gz`
- Local copy: `/home/mars-user/office-open-repro/crossover-sources-23.5.0.tar.gz`
- sha256: `ae9eb42a42be3e4e6d7cfc3fa224d15ec1bf8324742616ed7d5cd708bc8e9ee0`
- Contains `sources/wine/`; first extraction target:
  `/home/mars-user/office-open-repro/source-extract/sources/wine`
- Upstream comparison source: `https://dl.winehq.org/wine/source/8.0/wine-8.0.1.tar.xz`
- Local upstream copy: `/home/mars-user/office-open-repro/wine-8.0.1.tar.xz`
  - sha256: `22035f3836b4f9c3b1940ad90f9b9e3c1be09234236d2a80d893180535c75b7d`
- Extracted upstream source:
  `/home/mars-user/office-open-repro/upstream/wine-8.0.1`

## Clean local-Wine recipe

The current clean install succeeds with this combination:

1. Build and install the CodeWeavers 23.5 Wine source to
   `/home/mars-user/office-open-repro/wine-cx235-install`.
2. Create a fresh `win32` Windows 7 prefix.
3. Apply the Office DLL overrides captured from the CrossOver 23.5 recipe:
   `scripts/overrides/cx235-office-overrides.reg`.
4. Run archived ODT `12624-20320` against local Office cache
   `/home/mars-user/office-cache32-2002`. On an empty prefix this first pass may
   fail after staging Office files because `msoxmlmf.dll` is not materialized.
5. Copy Office's VFS `MSOXMLMF.DLL` into real
   `C:\Program Files\Common Files\Microsoft Shared\ClickToRun\msoxmlmf.dll`.
6. Install native `msxml6` with `winetricks -q msxml6`.
7. Rerun the same ODT configure. This pass should finish with exit code 0.
8. Launch `C:\Program Files\Microsoft Office\Root\Office16\EXCEL.EXE`.

The exact helper commands live in `scripts/repro-open-excel.sh`:

- `init-clean-prefix`
- `apply-cx235-overrides`
- `install-native-msxml6`
- `install-clean-prefix`
- `materialize-msoxmlmf`
- `launch-clean-prefix`

## Key findings

The successful clean prefix has a completed Click-to-Run/AppV registration:

- `HKLM\Software\Microsoft\AppVISV`
- `HKLM\Software\Microsoft\AppV\Client\Packages\...\COMIntegratedCLSIDs`
- `HKLM\Software\Microsoft\Office\16.0\ClickToRunStore\Applications`
- `HKLM\Software\Microsoft\Office\16.0\ClickToRunStore\Packages`
- `HKLM\Software\Microsoft\Office\ClickToRun\AppVMachineRegistryStore`

Earlier direct Wine/Proton attempts installed Office files, but failed during or
after Click-to-Run/AppV registration and then failed to show a workbook window.

Before native `msxml6`, the clean CodeWeavers-source Wine prefix still failed
late in Click-to-Run/AppV:

- SPP/MSI stage: `osppc.dll`/`osppcext.dll` errors and MSI 1603.
- ClickToRun runtime stage: missing `msoxmlmf.dll`.
- AppX manifest merge: `removeChild failed` with `0x80070057` / `30088-4`.

Installing native `msxml6` was the key fix for the AppX manifest merge failure.
Materializing `msoxmlmf.dll` handles the ClickToRun shared-DLL lookup.

## Candidate CrossOver patches for Office Click-to-Run

Diffs against upstream Wine 8.0.1 are in `/home/mars-user/office-open-repro/diffs`.

Most relevant so far:

- `dlls/rpcrt4/rpc_transport.c`
  - CrossOver adds `CXHACK 14391`.
  - It routes named-pipe RPC reads through `__wine_rpc_NtReadFile`.
  - The source comment says ClickToRun hooks `NtReadFile` and that hooked
    functions can re-enter RPC; avoiding the normal `NtReadFile` export avoids
    deadlocks.
- `dlls/ntdll/unix/file.c`
  - Adds `__wine_rpc_NtReadFile`, which calls `NtReadFile` internally but is
    exposed as a separate syscall/export path for the RPC transport.
- `dlls/ntdll/ntdll.spec`, `dlls/ntdll/unix/loader.c`
  - Registers/exports the new syscall.
- `dlls/wow64/file.c`, `dlls/wow64/syscall.h`
  - WOW64 plumbing for the same syscall.
- `dlls/kernelbase/file.c`
  - Adds `CXHACK 13427`: when `OfficeClickToRun.exe` calls
    `CreateSymbolicLinkW`, CrossOver copies the target file instead of treating
    the symlink call as a no-op.

The `rpcrt4`/`ntdll` patch is the strongest lead for why CrossOver avoids the
Click-to-Run/AppV/RPC failures seen in direct Wine/Proton attempts.

## Hypothesis

The reproducible open path is now:

1. Use an open Wine build close to CrossOver 23.5's base (`wine-8.0.1` plus the
   CodeWeavers patches above).
2. Create a clean `win32` Windows 7 prefix.
3. Apply CrossOver-equivalent bottle defaults and DLL overrides.
4. Run the archived older ODT setup, not the current `OfficeSetup.exe`.
5. Materialize `msoxmlmf.dll` from the staged Office VFS tree.
6. Install native `msxml6`.
7. Rerun ODT configure to completion.
8. Verify the AppV/ClickToRun registry is fully populated.
9. Launch `C:\Program Files\Microsoft Office\Root\Office16\EXCEL.EXE`.

The remaining open-source cleanup work is to reduce the CrossOver-derived
defaults to the smallest necessary set and move from CodeWeavers Wine source
toward Proton or a clean upstream Wine patch stack.

## Files in this workspace

- `scripts/inspect-working-crossover.sh`: captures the working baseline.
- `scripts/repro-open-excel.sh`: scaffold for the future open-source install/run script.
