# Excel on Linux

This repository captures the current working state of the Office/Excel-on-Linux
experiment.

## Current status

- Excel runs visibly on Linux using a locally built Wine runtime from the
  CodeWeavers CrossOver 23.5 source archive.
- The currently verified clean path installs Office into a fresh local-Wine
  prefix, then launches Excel from that same prefix.
- The clean path still depends on CrossOver-derived Wine source and bottle
  defaults as a reference, but it no longer depends on a CrossOver-created
  Office prefix.
- CrossOver is useful as a reference implementation, but CrossOver itself is
  proprietary. Its Wine source modifications are available as source archives.

Proof screenshots:

- `public/excel-clean-local-wine-signin.png`: Excel running from a clean local
  CodeWeavers-source Wine prefix after a successful Office install.
- `public/office-clean-install-complete.png`: the successful Office installer
  completion prompt from the clean local-Wine prefix.
- `public/excel-openwine-terminal-live.png`: earlier proof that a copied
  CrossOver-installed prefix runs under the local CodeWeavers-source Wine build.
- `public/office-final-verify.png`: earlier CrossOver 23.5 working fallback.

## Working launch on this machine

The clean-prefix launcher is:

```bash
PREFIX=/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides \
  /home/mars-user/office-open-repro/scripts/repro-open-excel.sh launch-clean-prefix
```

The clean install recipe, using local machine paths, is:

```bash
PREFIX=/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides \
  scripts/repro-open-excel.sh init-clean-prefix

PREFIX=/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides \
  OVERRIDES_REG=/home/mars-user/excel-on-linux/scripts/overrides/cx235-office-overrides.reg \
  scripts/repro-open-excel.sh apply-cx235-overrides

PREFIX=/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides \
  LOG_DIR=/home/mars-user/office-open-repro/logs-clean-overrides \
  scripts/repro-open-excel.sh install-clean-prefix || true

PREFIX=/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides \
  scripts/repro-open-excel.sh materialize-msoxmlmf

PREFIX=/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides \
  scripts/repro-open-excel.sh install-native-msxml6

PREFIX=/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides \
  LOG_DIR=/home/mars-user/office-open-repro/logs-clean-overrides \
  scripts/repro-open-excel.sh install-clean-prefix

PREFIX=/home/mars-user/.local/share/office-open-repro/prefix-clean-overrides \
  scripts/repro-open-excel.sh launch-clean-prefix
```

That expects these local paths to exist:

- Wine runtime: `/home/mars-user/office-open-repro/wine-cx235-install`
- Archived ODT setup: `/home/mars-user/office-odt/old-12624/setup.exe`
- Office XML: `/home/mars-user/office-odt/install-office32-2002-excelonly.xml`
- Office cache: `/home/mars-user/office-cache32-2002`

## What is included

- `progress.md`: the chronological work log.
- `scripts/`: inspection and reproduction helpers.
- `scripts/launchers/`: copies of the current launch wrappers.
- `scripts/overrides/`: registry data needed for the clean local-Wine Office
  prefix.
- `diffs/`: candidate CrossOver-vs-upstream Wine 8.0.1 diffs related to Office
  Click-to-Run/App-V behavior.
- `patches/`: narrowed patch artifacts extracted from those diffs for porting
  toward Proton.
- `docs/`: build and input notes.
- `public/`: relevant proof screenshots.

## What is intentionally not included

This repository does not commit Microsoft Office binaries, Office cache files,
CrossOver packages, CrossOver installations, copied Office prefixes, or compiled
Wine build outputs. Those are either proprietary, too large, machine-specific,
or generated from source.

See `docs/build-wine.md`, `docs/office-inputs.md`, and
`docs/proton-porting-notes.md` for the exact local inputs, hashes, and current
Proton patch target.
