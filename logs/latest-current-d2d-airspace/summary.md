# Latest Current D2D AirSpace Checkpoint

Date: 2026-05-31 06:01 UTC

Runtime: patched GE-Proton10-34 Wine runtime at `/home/mars-user/office-open-repro/valve-wine-ge10-install`.

Prefix: disposable latest/current Office WOW64 prefix at `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`.

Launch command:

```sh
timeout 120s env -u WAYLAND_DISPLAY OFFICE_SPP_NATIVE_POLICY_ERRORS=1 WINEDEBUG=+d2d,+messaging,+onlineid,fixme+combase,fixme+wintypes,err+ole,+loaddll WINEPREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx WINEARCH=win64 PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/bin:$PATH LD_LIBRARY_PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/lib XDG_RUNTIME_DIR=/run/user/1000 DISPLAY=:0 /home/mars-user/office-open-repro/valve-wine-ge10-install/bin/wine explorer /desktop=authprobe-x11-d2d3dtransform,1200x900 'C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE' /x
```

Changes tested:

- Added matrix/target diagnostics in `d2d1/device.c` for `SetTransform`, `SetTarget`, and bitmap draws.
- Registered a builtin stub for standard Direct2D `CLSID_D2D13DTransform` (`{e8467b04-ec61-4b8a-b5de-d4d73debea5a}`), next to the existing `3D Perspective Transform` stub.
- Built x86+x64 `d2d1.dll` and copied both into the patched runtime.
- Cleared `ExcelPreviousSessionId` and `ExcelPreviousSessionVersion` before launch to avoid the Safe Mode path.

Result:

- No Safe Mode prompt and no crash.
- The previous `Effect id {e8467b04-...} not found` warnings are gone; the log now shows `d2d_effect_create Created effect` for `CLSID_D2D13DTransform`.
- Excel still shows a blank centered `Sign in to set up Office` HWND (`850x542+535+269`).
- D2D logs prove Office is drawing sign-in text and controls into a 2048x1280 surface: `Sign in to get started with Excel`, `Sign in or create account`, and `Close Excel`.
- The final 2048x1280 WIC surface has real pixels (`nonzero 16508`, bounds `(1,5)-(1905,147)`), but the visible dialog remains blank.

Next likely target:

The blocker has moved past missing D2D SVG and missing `3D Transform` registration. The remaining gap appears to be the AirSpace/composition bridge or effect/image propagation from Office's rendered 2048x1280 surface into the visible centered sign-in HWND.
