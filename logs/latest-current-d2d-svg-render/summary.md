# Latest Current D2D SVG Render Probe

Date: 2026-05-31 05:10 UTC

Runtime: patched GE-Proton10-34 Wine build.

Prefix: `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`

Office target: latest/current 32-bit Excel (`16.0.20026.x`) in WOW64 Win10 prefix.

What changed:
- Added a focused `d2d1` SVG document/element store for Office's programmatic SVG path documents.
- Stored child links, `path d`, `viewBox`, fill color, fill opacity, and fill mode.
- Implemented a minimal path renderer for `M/m`, `L/l`, `H/h`, `V/v`, `C/c`, `Q/q`, and `Z/z`.
- Added `viewBox` scaling so `2048x2048` icon paths render into Office's small `54x54` SVG viewport.
- Built both x86 and x64 `d2d1.dll`; copied both into the patched runtime. The tested Excel process is 32-bit, so the x86 DLL is the exercised one.

Result:
- No Safe Mode prompt appeared after explicitly clearing Excel crash markers.
- No Excel crash during the 120s test window.
- `DrawSvgDocument` now creates path geometries and calls `FillGeometry`; the old pure no-op stub is no longer the immediate blocker.
- Visible state is still a blank white `Sign in to set up Office` panel over Excel.

Evidence:
- `excel-x11-svg-render-scaled.log`
- `xwininfo-svg-render-scaled.txt`
- `public/latest-current-excel-x11-svg-render-scaled-blank.png`

Next likely target:
- Determine why rendered SVG/WIC/D2D content is not visible in the sign-in surface despite path geometry being filled. Candidates: WIC render target composition/copy path, alpha/fill interpretation, or another React Native drawing layer after SVG rendering.
