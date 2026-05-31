# Latest current Excel D2D AirSpace standard-effect checkpoint

- Date: 2026-05-31 07:10 UTC
- Prefix: `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`
- Runtime: patched GE-Proton10-34 Wine install at `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Launch: X11 virtual desktop `authprobe-x11-d2d-airspace-node`, latest/current 32-bit Excel from `C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE /x`

## Change Tested

- Registered builtin Direct2D `CLSID_D2D1Atlas` (`{913e2be4-fdcf-4fe2-a5f0-2454f14ff408}`) with conservative `InputRect` and `InputPaddingRect` properties.
- Registered builtin Direct2D `CLSID_D2D1ColorMatrix` (`{921f03d6-641c-47df-852d-b4bb6153ae11}`) with conservative identity matrix properties.
- Registered builtin Direct2D `CLSID_D2D1Flood` (`{61c23c20-ae69-4d8e-94cf-50078df638f2}`) with conservative color property.
- Relaxed Wine's D2D effect graph initialization so custom transform nodes that do not require `ID2D1DrawInfo` do not fail only because they are not `ID2D1DrawTransform`.
- Rebuilt and copied x86+x64 `d2d1.dll` into the patched runtime.
- Cleared disposable Excel Safe Mode markers before launch; no Safe Mode prompt appeared.

## Result

- The previous Atlas, ColorMatrix, and Flood missing-effect warnings are gone.
- The previous `d2d_effect_transform_graph_initialize_nodes Unsupported node ...` failures are gone; AirSpace effect instances now report `Node ... does not require draw info` and `Created effect`.
- Latest Excel still reaches the same visible blank `Sign in to set up Office` window.
- D2D/WIC evidence still shows the sign-in UI is rendered offscreen: `Sign in to get started with Excel`, `Sign in or create account`, and `Close Excel` glyphs appear in the trace; the 2048x1280 surface has `nonzero 16846`, bounds `(1,5)-(1979,147)`.
- New next missing standard effect is `CLSID_D2D1Scale` (`{9daf9369-3846-4d0e-a44e-0c607934a5d7}`).

## Evidence

- Main log: `excel-x11-d2d-flood2.log`
- Main window tree: `xwininfo-d2d-flood2.txt`
- Main screenshot: `public/latest-current-excel-x11-d2d-flood2-blank.png`
- Earlier Atlas/node log: `excel-x11-d2d-airspace-node.log`
- Patch: `patches/latest-current-d2d-atlas-airspace-node.patch`

## Next Lead

Continue registering the standard D2D effects reached by Office's AirSpace graph, starting with `CLSID_D2D1Scale`; once the standard effect chain stops failing at creation time, return to the effect image/output or WIC/HWND presentation bridge into the visible sign-in client area.
