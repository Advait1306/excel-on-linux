# Latest Installer Investigation

This lane is separate from the known-good Office `16.0.12527.21416` prefix.
Do not reuse or overwrite the known-good prefix.

## Baseline

- Known-good runtime:
  `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Known-good prefix:
  `/home/mars-user/.local/share/office-proton/compatdata/office-ge10-odt2002-wow64/pfx`
- Known-good Office payload: 32-bit Excel-only Office `16.0.12527.21416`

## Experimental Defaults

- Driver: `scripts/office-latest-experiment.sh`
- Experimental prefix:
  `/home/mars-user/.local/share/office-proton/compatdata/latest-officesetup-win10/pfx`
- Architecture: WOW64, `WINEARCH=win64`
- Windows version: `win10`
- Current bootstrapper:
  `/home/mars-user/OfficeSetup.exe`
  - SHA256: `1dd6491f068d450cd686b31e4574da540ad8948bdf1cebbc7feba215fe2c7d2c`
- Current local ODT:
  `/home/mars-user/office-odt/setup.exe`
  - SHA256: `22fc10ddbab93122fcae58cf5d8fef9724c3a7375c29c9c340d2de5682fab49c`
- Current-channel Excel-only XML:
  `config/office-latest-excelonly-current.xml`

## Commands

```bash
scripts/office-latest-experiment.sh inspect
scripts/office-latest-experiment.sh init-prefix
scripts/office-latest-experiment.sh apply-overrides
scripts/office-latest-experiment.sh install-native-msxml6
scripts/office-latest-experiment.sh install-winscard-stub
scripts/office-latest-experiment.sh run-officesetup
```

If `OfficeSetup.exe` fails too early or is too opaque, use:

```bash
scripts/office-latest-experiment.sh run-latest-odt
```

## Results So Far

### Current `OfficeSetup.exe`

Prefix:

```text
/home/mars-user/.local/share/office-proton/compatdata/latest-officesetup-win10/pfx
```

Command:

```bash
scripts/office-latest-experiment.sh run-officesetup
```

Observed behavior:

- Starts under the patched GE runtime.
- Shows a blank Microsoft installer window.
- Chooses `platform=x64` and the full `O365HomePremRetail` app target set from CDN.
- Reaches real download activity, but remains opaque and does not follow the Excel-only 32-bit configuration.

Notable log evidence:

- Delivery Optimization is unavailable: `0x80040154`.
- BITS resume path reports `0x80200003`.
- C2R falls back to HTTP and prepares ranged stream downloads.

This lane is useful as evidence that the bootstrapper starts, but it is not the preferred reproducible lane because it does not let us control bitness/app selection.

### Current ODT, Current Channel, 32-bit Excel-only

Prefix:

```text
/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx
```

Command:

```bash
PREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-latest-odt-current32-win10 \
scripts/office-latest-experiment.sh run-latest-odt
```

Observed C2R arguments:

```text
platform=x86
productstoadd=O365HomePremRetail.16_en-us_x-none
version.16=16.0.20026.20112
O365HomePremRetail.excludedapps.16=access,groove,lync,onedrive,onenote,outlook,powerpoint,publisher,teams,word
updatesenabled.16=False
autoactivate=0
acceptalleulas.16=True
```

Final observed state on 2026-05-30 08:24 UTC:

- Ran for about 1h55m and reached a Microsoft error dialog.
- C2R log progress reached `78%`.
- Prefix size stabilized at `5,738,506,491` bytes over a 20s sample; this is no longer actively downloading payloads.
- `EXCEL.EXE` exists in the final Office path:
  `C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE`
  - Linux path:
    `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx/drive_c/Program Files (x86)/Microsoft Office/root/Office16/EXCEL.EXE`
  - Size: `55,924,032` bytes
- Proton shortcut files were created under:
  `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx/drive_c/proton_shortcuts/`
  including `Excel.desktop`.
- Screenshot:
  `public/latest-odt-current32-win10-error-78.png`

Final dialog:

```text
Something went wrong
Sorry, we ran into a problem.
Error Code: 30015-11 (3221225477)
```

Measured throughput:

- Network receive: about `21.5 MiB/min`, roughly `3.0 Mbps`.
- Prefix growth: about `50.2 MiB/min`.

Notable log evidence:

- Delivery Optimization cannot be created: `0x80040154`.
- C2R succeeds by falling back to HTTP.
- MSA telemetry token requests fail with `0x80004001`; observed as telemetry noise so far, not an install stop.
- Repeated warning:
  `GetTrustLevelOnFile failed getting proc addr for get/set cached signing level.`
- The fatal error is later, during the integrate/license task:

```text
C:\Program Files (x86)\Microsoft Office\root\integration\integrator.exe
  /I /License PRIDName=O365HomePremRetail.16
  /C2R PackageGUID="9AC08E99-230B-47e8-9721-4577B7F124EA"
  PackageRoot="C:\Program Files (x86)\Microsoft Office\root"

TaskIntegrate::RunIntegrator:
  ErrorCode: 3221225477
  ErrorMessage: ErrorCodeOnly (Licenses Installation. , Error:0xc0000005)
```

Relevant log:

```text
/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx/drive_c/users/steamuser/AppData/Local/Temp/IP-172-31-32-32-20260530-0626b.log
```

Interpretation:

The current ODT lane is the better reproducible path. It is using the intended WOW64/x86 Excel-only configuration in our own patched GE Wine prefix, and it gets substantially past startup/download into final Office integration. The current blocker is not raw network speed: the payload appears downloaded and staged, but modern Current Channel Office crashes `integrator.exe` during C2R license integration with `0xc0000005`, surfaced by the installer as `30015-11 (3221225477)`.
