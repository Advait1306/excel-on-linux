# Latest current Excel: Microsoft.UI DispatcherQueue alias

- Prefix: `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`
- Runtime: patched GE-Proton10 Wine install at `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Test desktop: `authprobe-x11-coremessagingxp-alias`
- Crash markers cleared before launch:
  - `HKCU\Software\Microsoft\Office\16.0\Excel\ExcelPreviousSessionId`
  - `HKCU\Software\Microsoft\Office\16.0\Excel\ExcelPreviousSessionVersion`
- Disposable prefix change for this test:
  - Backed up native `C:\windows\syswow64\CoreMessagingXP.dll` to `.officebak`.
  - Replaced `C:\windows\syswow64\CoreMessagingXP.dll` with the patched 32-bit Wine `coremessaging.dll` build to force the Microsoft.UI class through our dispatcher shim.
- Result:
  - No Safe Mode prompt appeared.
  - `Microsoft.UI.Dispatching.DispatcherQueue` activated through builtin `CoreMessagingXP.dll`.
  - The alias for IID `{cd3382ea-a455-5124-b63a-ca40d34ca23c}` was exercised.
  - Excel still reaches a blank `Sign in to set up Office` window over `Excel (Non-Commercial Use) (Unlicensed Product)`.
- Evidence:
  - `excel-x11-coremessagingxp-alias.log`
  - `xwininfo-msui-dispatcher.txt`
  - `../../public/latest-current-excel-x11-coremessagingxp-alias-signin-blank.png`
