# Latest Current DWM Caption Bounds Checkpoint

Date: 2026-05-31 06:26 UTC

Runtime: patched GE-Proton10-34 Wine runtime at `/home/mars-user/office-open-repro/valve-wine-ge10-install`.

Prefix: disposable latest/current Office WOW64 prefix at `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`.

Changes tested:

- Rebuilt/copied x86+x64 `dwmapi.dll` from the patched Wine tree so this runtime includes existing `DWMWA_EXTENDED_FRAME_BOUNDS` handling.
- Added `DwmGetWindowAttribute(DWMWA_WINDOW_CORNER_PREFERENCE)` returning default `0`.
- Added `DwmGetWindowAttribute(DWMWA_CAPTION_BUTTON_BOUNDS)` returning a reasonable caption-button rectangle for non-child windows.
- Cleared `ExcelPreviousSessionId` and `ExcelPreviousSessionVersion` before launching latest Excel.

Result:

- No Safe Mode prompt and no crash.
- The visible sign-in window changed from a border-only blank panel to a normal Wine-decorated window titled `Sign in to set up Office`.
- `DWMWA_WINDOW_CORNER_PREFERENCE` and `DWMWA_CAPTION_BUTTON_BOUNDS` are now handled in the log; the repeated `attribute 5 not implemented` messages are gone.
- The sign-in client area remains blank.
- Office still renders sign-in text into a 2048x1280 D2D/WIC surface (`Sign in to get started with Excel`, `Sign in or create account`, `Close Excel`). The final surface has real pixels (`nonzero 16846`, bounds `(1,5)-(1979,147)`).

Next likely target:

The remaining blocker is not DWM caption metadata. It is still the path that presents Office's rendered D2D/AirSpace surface into the visible sign-in HWND client area.
