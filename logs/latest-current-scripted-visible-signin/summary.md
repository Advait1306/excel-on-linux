# Scripted latest/current Excel visible sign-in verification

- Date: 2026-05-31 08:02 UTC
- Script: `scripts/office-latest-experiment.sh`
- Prefix: `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx`
- Runtime: `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Virtual desktop: `authprobe-script-verify2,1200x900`

## Commands

```bash
PREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-latest-authprobe \
scripts/office-latest-experiment.sh clear-excel-resiliency

timeout 120s env \
  PREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
  LOG_DIR=/home/mars-user/office-open-repro/logs-latest-authprobe \
  VIRTUAL_DESKTOP=authprobe-script-verify2,1200x900 \
  scripts/office-latest-experiment.sh launch-excel-x11-log
```

## Result

- No Safe Mode prompt.
- No `702061` repair event in the checked log lines.
- No `Effect id ... not found` in the checked log lines.
- Window tree shows:
  - `Excel (Non-Commercial Use) (Unlicensed Product)`
  - `Sign in to set up Office`
- D2D text traces include:
  - `Sign in to get started with Excel`
  - `Sign in or create account`
  - `Close Excel`

This confirms the new script can reproduce the latest/current visible sign-in
checkpoint without CrossOver.
