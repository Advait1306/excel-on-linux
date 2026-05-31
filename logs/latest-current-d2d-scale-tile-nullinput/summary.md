# Latest Office D2D scale/tile/null-input checkpoint

- Date: 2026-05-31 UTC
- Prefix: `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`
- Runtime: patched GE-Proton10-34 Wine build in `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Office: latest/current Click-to-Run Excel `16.0.20026.20112`, 32-bit Office inside WOW64 Win10 prefix.

## Changes tested

- Added builtin D2D effect metadata for `CLSID_D2D1Scale`.
- Added builtin D2D effect metadata for `CLSID_D2D1Tile`.
- Fixed `ID2D1Effect::SetInput()` to allow `input == NULL`; Excel uses this to clear an input after Tile is registered.
- Deleted `HKCU\Software\Microsoft\Office\16.0\Excel\Resiliency` before the final rerun. Deleting only `ExcelPreviousSessionId` and `ExcelPreviousSessionVersion` was insufficient after the Tile crash.

## Result

- Scale and Tile are now created by `d2d1`; no `Effect id ... not found` remains in the successful rerun log.
- The Tile registration exposed a real null deref in `d2d1` at `SetInput(NULL)`; the null-input guard fixes that crash.
- Safe Mode prompt can focus `Yes` by default. Do not press Enter on that dialog. Clear the Excel `Resiliency` key or explicitly select `No`.
- After clearing `Resiliency`, latest Excel visibly reaches the Home screen and visible `Sign in to set up Office` dialog. This is a major improvement over the prior blank sign-in client.

## Evidence

- `excel-x11-d2d-scale.log`: Scale clears the prior missing-effect warning and exposes missing Tile.
- `excel-x11-d2d-tile-crash.log`: Tile is created, then Excel crashes in `d2d1` after `SetInput(... input 00000000 ...)`.
- `excel-x11-d2d-resiliencyclean.log`: successful visible launch with no Safe Mode prompt.
- `xwininfo-d2d-resiliencyclean.txt`: confirms `Excel (Non-Commercial Use) (Unlicensed Product)` and `Sign in to set up Office` windows are present.
