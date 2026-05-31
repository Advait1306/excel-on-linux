# Latest/current Excel visible sign-in checkpoint

Date: 2026-05-31 UTC

This is the current best latest/current Office lane. It is separate from the
known-good older Office `16.0.12527.21416` prefix.

## Prefix and runtime

- Runtime: `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Wine version string: `wine-8.0-15655-g1729f00e17`
- Prefix:
  `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`
- Architecture: WOW64, `WINEARCH=win64`
- Windows version: Windows 10
- Office payload: latest/current 32-bit Click-to-Run Excel,
  `16.0.20026.20112`

## Current launch command

Use the repo driver with the authprobe prefix and current evidence log dir:

```bash
PREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-latest-authprobe \
VIRTUAL_DESKTOP=authprobe-x11-visible,1200x900 \
scripts/office-latest-experiment.sh clear-excel-resiliency

PREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-latest-authprobe \
VIRTUAL_DESKTOP=authprobe-x11-visible,1200x900 \
scripts/office-latest-experiment.sh launch-excel-x11-log
```

`OFFICE_SPP_NATIVE_POLICY_ERRORS=1` is set by `launch-excel-x11-log` unless
overridden. This preserves the builtin `sppc` behavior that currently avoids
Office repair event `702061`.

## Safe Mode rule

Excel's Safe Mode prompt focuses `Yes` by default. Do not press Enter on this
dialog. Either:

- run `clear-excel-resiliency` before launch, or
- explicitly click/select `No` if the prompt appears.

Deleting only `ExcelPreviousSessionId` and `ExcelPreviousSessionVersion` was
not sufficient after the Tile/null-input crash. Deleting
`HKCU\Software\Microsoft\Office\16.0\Excel\Resiliency` suppressed the prompt in
the successful run.

## Current result

Latest/current Excel now visibly reaches:

- main window: `Excel (Non-Commercial Use) (Unlicensed Product)`
- dialog: `Sign in to set up Office`
- visible sign-in content: `Sign in to get started with Excel`,
  `Sign in or create account`, `I have a product key`, and `Close Excel`

Evidence:

- `public/latest-current-excel-x11-d2d-visible-signin.png`
- `logs/latest-current-d2d-scale-tile-nullinput/excel-x11-d2d-resiliencyclean.log`
- `logs/latest-current-d2d-scale-tile-nullinput/xwininfo-d2d-resiliencyclean.txt`

## Most recent runtime fixes behind this checkpoint

- D2D standard effect registrations: `3DTransform`, `Atlas`, `ColorMatrix`,
  `Flood`, `Scale`, and `Tile`.
- D2D effect graph relaxation for custom transform nodes that do not require
  `ID2D1DrawInfo`.
- `ID2D1Effect::SetInput()` null-input guard; latest Excel clears effect input
  slots with `NULL`.
- D2D SVG document/path rendering and WIC diagnostics from earlier checkpoints.
- DWM caption/corner metadata stubs for the Office sign-in HWND.
- WinRT/AppX/SPP/OnlineId shims documented in the patch stack and progress log.

## Next human boundary

The latest/current lane has reached a Microsoft account/product-key sign-in
step. Continuing past this point may require the user's Microsoft identity and
license decisions.
