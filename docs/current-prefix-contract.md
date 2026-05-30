# Current Prefix Contract

This is the target setup after the 2026-05-30 steering update. Stock Proton is
not required for this checkpoint; the runtime dependency is the patched
GE-Proton10-34 Wine build documented in `docs/build-wine.md`.

## Runtime

- Required runtime: `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Version string: `wine-8.0-15655-g1729f00e17`
- Required patch: CrossOver/CX `__wine_rpc_NtReadFile` AppV RPC fix ported to
  GE-Proton10-34 Wine.
- Verification: both i386 and x86_64 `ntdll.so` export
  `__wine_rpc_NtReadFile`, and both i386 and x86_64 `rpcrt4.dll` import/export
  that symbol.

## Prefix

- Prefix path:
  `/home/mars-user/.local/share/office-proton/compatdata/office-ge10-odt2002-wow64/pfx`
- Architecture: WOW64, `WINEARCH=win64`, because this path needs 64-bit support
  for Office setup components while installing 32-bit Office apps.
- Windows version: Windows 7.
- Office app payload: 32-bit Excel-only Office 365, SemiAnnual channel,
  version `16.0.12527.21416`.

## Required Prefix Content

- Apply `scripts/overrides/cx235-office-overrides.reg`.
- Install native `msxml6` with `winetricks -q msxml6`.
- Install the 64-bit `WinSCard.dll` stub from `proton-stubs/winscard_stub.c`
  into `drive_c/windows/system32/WinSCard.dll`.
- Set Wine DLL override `winscard=native,builtin`.
- If Click-to-Run cannot find `msoxmlmf.dll`, copy Office's VFS copy from:
  `Program Files (x86)/Microsoft Office/root/vfs/ProgramFilesCommonX86/Microsoft Shared/OFFICE16/MSOXMLMF.DLL`
  to:
  `Program Files (x86)/Common Files/Microsoft Shared/ClickToRun/msoxmlmf.dll`.

## Office Deployment

- ODT setup:
  `/home/mars-user/office-odt/old-12624/setup.exe`
- XML in repo:
  `config/office32-2002-excelonly.xml`
- Local payload cache:
  `/home/mars-user/office-cache32-2002`

## Driver Script

Use `scripts/office-ge10-prefix.sh` as the restartable entrypoint:

```bash
scripts/office-ge10-prefix.sh inspect
scripts/office-ge10-prefix.sh init-prefix
scripts/office-ge10-prefix.sh apply-overrides
scripts/office-ge10-prefix.sh install-native-msxml6
scripts/office-ge10-prefix.sh install-winscard-stub
scripts/office-ge10-prefix.sh install-office
scripts/office-ge10-prefix.sh materialize-msoxmlmf
scripts/office-ge10-prefix.sh launch-excel
```
