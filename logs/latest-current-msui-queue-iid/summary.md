# Latest current Excel: Microsoft.UI IDispatcherQueue alias

- Prefix: `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`
- Runtime: patched GE-Proton10 Wine install at `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Test desktop: `authprobe-x11-msui-queue-iid`
- Safe Mode handling:
  - Cleared `ExcelPreviousSessionId` and `ExcelPreviousSessionVersion` before launch.
  - No Safe Mode prompt appeared.
- Patch:
  - `Microsoft.UI.winmd` from the Office install identifies `{f6ebf8fa-be1c-5bf6-a467-73da28738ae8}` as `Microsoft.UI.Dispatching.IDispatcherQueue`.
  - Added an alias in builtin `coremessaging.dll` so that IID resolves to the existing `Windows.System.IDispatcherQueue` shim.
- Result:
  - Previous `queue_QueryInterface ... {f6ebf8fa-...} not implemented` is cleared.
  - Excel still reaches a blank `Sign in to set up Office` window.
  - The next concrete blocker is Direct2D SVG rendering: Office creates SVG path content for the sign-in surface, including the Microsoft wordmark and background paths, but `d2d_device_context_DrawSvgDocument` is still a no-op.
- Evidence:
  - `excel-x11-msui-queue-iid.log`
  - `xwininfo-msui-queue-iid.txt`
  - `../../public/latest-current-excel-x11-msui-queue-iid-signin-blank.png`
