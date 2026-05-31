# Current GE10 Office patch stack

Date: 2026-05-31 09:58 UTC

This documents the patched GE-Proton10-34 Wine source/runtime state that
reproduces latest/current Excel reaching the visible sign-in/product-key step.
It is not the older known-good Office `16.0.12527.21416` prefix.

## Source base

- Source tree: `/home/mars-user/office-open-repro/valve-wine-ge10-src`
- Upstream commit: `1729f00e17e879f98f9df1f2bca86bc5d21a65df`
- Runtime install: `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Runtime version: `wine-8.0-15655-g1729f00e17`

## Patch artifacts

- Tracked source changes:
  `patches/current-runtime/ge10-office-current-tracked.patch`
- Focused latest-ODT reintegration patch:
  `patches/current-runtime/ge10-office-appxdeploymentclient-stagepackageoptions.patch`
- New Office shim source files:
  `patches/current-runtime/ge10-office-current-new-source-files.patch`
- Full untracked-file inventory:
  `patches/current-runtime/ge10-office-untracked-files.txt`

The new-source patch intentionally excludes generated build files and Vulkan
generated files from the current source tree inventory:

- `configure`
- `include/config.h.in`
- `dlls/ntdll/ntsyscalls.h`
- `dlls/win32u/win32syscalls.h`
- `dlls/vulkan-1/*`
- `dlls/winevulkan/*`
- `include/wine/vulkan.h`

Those generated files may exist in the local build tree but are not part of
the Office-specific patch recipe.

## Runtime manifest

- Runtime DLL hashes:
  `logs/current-runtime-manifest/runtime-sha256.txt`
- Source/runtime version and diffstat:
  `logs/current-runtime-manifest/source-and-runtime-version.txt`
- Latest Excel binary size/hash:
  `logs/current-runtime-manifest/latest-office-binaries-size.txt`
  and `logs/current-runtime-manifest/latest-office-binaries-sha256.txt`
- Latest experimental prefix size:
  `logs/current-runtime-manifest/latest-prefix-size.txt`

## Latest-current reproduction boundary

The current reproducible latest path is documented in:

- `docs/latest-current-visible-signin.md`
- `logs/latest-current-scripted-visible-signin/summary.md`
- `public/latest-current-excel-scripted-visible-signin.png`

It reaches the current Excel Home screen and the `Sign in to set up Office`
dialog under our patched runtime. This is a human decision boundary: continuing
requires Microsoft account/product-key interaction.

The 2026-05-31 09:58 UTC snapshot also includes the current-ODT reintegration
fix for `Windows.Management.Deployment.StagePackageOptions` in
`appxdeploymentclient.dll`. Prefixes need both native and WOW64 WinRT
registration for that class; use `scripts/office-latest-experiment.sh
prepare-current-launch` after rebuilding/copying the runtime DLL.

## Applying the source snapshot

From a clean GE10 source tree at the base commit:

```bash
cd /home/mars-user/office-open-repro/valve-wine-ge10-src
git apply /home/mars-user/excel-on-linux/patches/current-runtime/ge10-office-current-new-source-files.patch
git apply /home/mars-user/excel-on-linux/patches/current-runtime/ge10-office-current-tracked.patch
```

Then rebuild/install the required i386 and x86_64 DLLs into
`/home/mars-user/office-open-repro/valve-wine-ge10-install`. The current
runtime hash manifest is the verification target.
