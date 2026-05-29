# Excel on Linux

This repository captures the current working state of the Office/Excel-on-Linux
experiment.

## Current status

- Excel runs visibly on Linux using a locally built Wine runtime from the
  CodeWeavers CrossOver 23.5 source archive.
- The currently verified launch uses a copied Office prefix that was installed
  successfully by CrossOver 23.5, then run with the locally built Wine runtime.
- The clean, fully open installer path is not solved yet. The main blocker is
  Office Click-to-Run/App-V registration and runtime RPC behavior.
- CrossOver is useful as a reference implementation, but CrossOver itself is
  proprietary. Its Wine source modifications are available as source archives.

Proof screenshots:

- `public/excel-openwine-terminal-live.png`: Excel running under the local
  CodeWeavers-source Wine build.
- `public/office-final-verify.png`: earlier CrossOver 23.5 working fallback.

## Working launch on this machine

The most reliable current launcher is:

```bash
/home/mars-user/.local/bin/excel-openwine-direct-from-cx235
```

Or from this repo copy:

```bash
scripts/repro-open-excel.sh launch-copied-prefix-terminal
```

That expects these local paths to exist:

- Wine runtime: `/home/mars-user/office-open-repro/wine-cx235-install`
- Office prefix: `/home/mars-user/.local/share/office-open-repro/prefix-from-cx235`

## What is included

- `progress.md`: the chronological work log.
- `scripts/`: inspection and reproduction helpers.
- `scripts/launchers/`: copies of the current launch wrappers.
- `diffs/`: candidate CrossOver-vs-upstream Wine 8.0.1 diffs related to Office
  Click-to-Run/App-V behavior.
- `docs/`: build and input notes.
- `public/`: relevant proof screenshots.

## What is intentionally not included

This repository does not commit Microsoft Office binaries, Office cache files,
CrossOver packages, CrossOver installations, copied Office prefixes, or compiled
Wine build outputs. Those are either proprietary, too large, machine-specific,
or generated from source.

See `docs/build-wine.md` and `docs/office-inputs.md` for the exact local inputs
and hashes used in this run.
