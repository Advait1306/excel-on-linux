# Latest Current D2D WIC Pixel Probe

Date: 2026-05-31 05:25 UTC

Runtime: patched GE-Proton10-34 Wine build.

Prefix: `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`

Office target: latest/current 32-bit Excel (`16.0.20026.x`) in WOW64 Win10 prefix.

What changed:
- Kept the focused D2D SVG path renderer from the previous checkpoint.
- Added diagnostics for SVG fill colors.
- Added WIC render-target pixel diagnostics: nonzero pixel count, alpha pixel count, nonzero bounds, and checksum.

Result:
- No Safe Mode prompt appeared after clearing `ExcelPreviousSessionId` and `ExcelPreviousSessionVersion`.
- No crash in the 120s test window.
- SVG fill values are valid Office/Microsoft colors, not garbage.
- Individual SVG WIC surfaces contain real pixels:
  - Background `850x161`: `122113` nonzero/alpha pixels, bounds `(0,0)-(849,160)`.
  - Microsoft wordmark `108x24`: `766` nonzero/alpha pixels, bounds `(0,2)-(106,22)`.
  - App icons `54x54`: thousands of nonzero/alpha pixels with expected bounds.
- Large composed `2048x1280` WIC surfaces contain only top-strip content, e.g. bounds `(1,5)-(2035,147)`.
- Visible state is still a blank centered `Sign in to set up Office` window.

Interpretation:
- The blocker is no longer SVG path parsing, fill color decoding, or WIC readback/pixel generation.
- The next likely target is the host surface / visual / window attachment path: rendered content is produced offscreen, but the centered sign-in HWND is not receiving or presenting it.

Evidence:
- `excel-x11-wic-bounds.log`
- `xwininfo-wic-bounds.txt`
- `public/latest-current-excel-x11-wic-bounds-blank.png`
