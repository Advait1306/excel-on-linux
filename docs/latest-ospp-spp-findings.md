# Latest Office OSPP/SPP Findings

Checkpoint: 2026-05-30 20:54 UTC

This documents the current/latest Office path, not the known-good archived
Office `16.0.12527.21416` path.

## Current State

- Runtime:
  `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Prefix:
  `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx`
- Prefix architecture: WOW64, `WINEARCH=win64`
- Windows version: `win10`
- Office payload: Current Channel, 32-bit Excel-only, `16.0.20026.20112`
- Launch command:

```bash
PREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-latest-odt-current32-win10 \
/home/mars-user/excel-on-linux/scripts/office-latest-experiment.sh launch-excel-log
```

## Evidence

The current x86 Office manifest contains OfficeSoftwareProtectionPlatform files
only under `ProgramFilesCommonX64`. It does not list a
`ProgramFilesCommonX86\Microsoft Shared\OfficeSoftwareProtectionPlatform`
payload.

Command used:

```bash
strings -el -n 4 \
  /home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx/drive_c/ProgramData/Microsoft/ClickToRun/ProductReleases/3BAE83F9-3005-46F6-B350-D3C956657002/x-none.16/stream.x86.x-none.man.dat \
  | grep -i 'OfficeSoftwareProtectionPlatform\|OSPPC\|OSPPSVC\|OSPPOBJS\|OSPPCEXT'
```

Relevant output:

```text
root\vfs\ProgramFilesCommonX64\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPC.DLL
root\vfs\ProgramFilesCommonX64\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPOBJS.DLL
root\vfs\ProgramFilesCommonX64\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPCEXT.DLL
root\vfs\ProgramFilesCommonX64\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPSVC.EXE
```

The materialized latest diagnostic has:

```text
C:\Program Files\Common Files\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPC.DLL
C:\Program Files\Common Files\Microsoft Shared\ClickToRun\0\osppc.dll
C:\windows\system32\sppc.dll
```

The 32-bit `C:\windows\syswow64\sppc.dll` currently comes from the older
known-good Office OSPPC because no current x86 OSPPC was found in the latest
install payload.

## What Changed Behavior

Without native OSPP/SPP, latest Excel emits Office repair event `702061`:

```text
Microsoft Excel
We're sorry, but Excel has run into an error...
version 16.0.20026.20112
token 8qeyi
```

Materializing latest x64 OSPP and adding `ClickToRun\0\osppc.dll` fixed an
earlier load failure but did not clear the repair event by itself.

Forcing `sppc=native,builtin` and replacing `system32/syswow64\sppc.dll` with
native Office OSPPC made `OSPPSVC.EXE` run and cleared `702061`. Excel reached:

```text
Microsoft respects your privacy
Excel (Non-Commercial Use) (Unlicensed Product)
```

Screenshots:

- `public/latest-current-excel-after-clicktorun-osppc.png`
- `public/latest-current-excel-privacy-dialog-native-osppc-sppc.png`

## Reproduction Helper

Diagnostic helper:

```bash
/home/mars-user/excel-on-linux/scripts/experiments/latest-native-ospp-diagnostic.sh status
/home/mars-user/excel-on-linux/scripts/experiments/latest-native-ospp-diagnostic.sh apply
/home/mars-user/excel-on-linux/scripts/experiments/latest-native-ospp-diagnostic.sh restore
```

This helper is intentionally labeled diagnostic. It proves the blocker is in
Wine's SPP/OSPP behavior, but it is not the final open-runtime implementation
because it borrows native Office protection DLLs.

## Next Engineering Target

The next open-runtime task is to replace the native `sppc` dependency with a
Wine implementation that behaves enough like Office OSPP/SPP for this current
build:

- materialize or emulate the OSPP service/path expectations;
- satisfy Click-to-Run's `osppc.dll` lookup;
- implement the SPP authentication/result path behind Excel's 288-byte
  `SLSetAuthenticationData` challenge;
- preserve the latest/current Excel path and keep the older archived Office
  prefix untouched.

Native OSPPC exports 55 `SL*`/`SLp*` entry points. The current Wine `sppc`
worktree implements the functions Excel has reached so far, but the saved logs
do not contain the full 288-byte authentication challenge anymore. Only the
first bytes were preserved in `progress.md`:

```text
20 01 00 00 01 00 00 00 00 00 01 00 0c 01 00 00
01 02 00 00 10 66 00 00 00 a4 00 00 c1 9c ef 06 ...
```

Do not implement the final auth response from this partial blob. The next clean
step is to capture the full `SLSetAuthenticationData` payload again in a
disposable restored/builtin-SPP test prefix, then feed those bytes to native
OSPP with a small probe to observe the real `SLGetAuthenticationResult` output.
