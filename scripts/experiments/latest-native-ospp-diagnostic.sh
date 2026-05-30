#!/usr/bin/env bash
set -euo pipefail

# Diagnostic only: materialize Office's native OSPP pieces in the disposable
# latest prefix and force sppc to native,builtin. This proved the 702061 repair
# path is tied to Wine's sppc emulation, but the 32-bit OSPPC source below is
# from the older known-good Office install because the latest x86 install did
# not contain one.

PREFIX="${PREFIX:-/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx}"
RUNTIME_ROOT="${RUNTIME_ROOT:-/home/mars-user/office-open-repro/valve-wine-ge10-install}"
LATEST_ROOT="${LATEST_ROOT:-$PREFIX/drive_c/Program Files (x86)/Microsoft Office/root}"
OLD_GOOD_PREFIX="${OLD_GOOD_PREFIX:-/home/mars-user/.local/share/office-proton/compatdata/office-ge10-odt2002-wow64/pfx}"

WINEBIN="$RUNTIME_ROOT/bin/wine"

latest_ospp_x64="$LATEST_ROOT/vfs/ProgramFilesCommonX64/Microsoft Shared/OfficeSoftwareProtectionPlatform"
target_ospp_x64="$PREFIX/drive_c/Program Files/Common Files/Microsoft Shared/OfficeSoftwareProtectionPlatform"
clicktorun_ospp="$PREFIX/drive_c/Program Files/Common Files/Microsoft Shared/ClickToRun/0"
old_ospp_x86="$OLD_GOOD_PREFIX/drive_c/Program Files (x86)/Common Files/Microsoft Shared/OfficeSoftwareProtectionPlatform"

wine_reg() {
  WINEPREFIX="$PREFIX" WINEARCH=win64 \
    PATH="$RUNTIME_ROOT/bin:$PATH" \
    LD_LIBRARY_PATH="$RUNTIME_ROOT/lib:$RUNTIME_ROOT/lib/wine${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$WINEBIN" reg "$@"
}

mkdir -p "$target_ospp_x64" "$clicktorun_ospp"
cp "$latest_ospp_x64"/{OSPPC.DLL,OSPPCEXT.DLL,OSPPOBJS.DLL,OSPPSVC.EXE,OSPPWMI.DLL,OSPPWMI.MOF,osppobjs-spp-plugin-manifest-signed.xrm-ms} "$target_ospp_x64/"
cp "$target_ospp_x64/OSPPC.DLL" "$clicktorun_ospp/osppc.dll"
cp "$target_ospp_x64/OSPPC.DLL" "$PREFIX/drive_c/windows/system32/osppc.dll"

if [[ ! -f "$PREFIX/drive_c/windows/system32/sppc.dll.before-osppc-test" ]]; then
  cp "$PREFIX/drive_c/windows/system32/sppc.dll" "$PREFIX/drive_c/windows/system32/sppc.dll.before-osppc-test"
fi
if [[ ! -f "$PREFIX/drive_c/windows/syswow64/sppc.dll.before-osppc-test" ]]; then
  cp "$PREFIX/drive_c/windows/syswow64/sppc.dll" "$PREFIX/drive_c/windows/syswow64/sppc.dll.before-osppc-test"
fi

cp "$target_ospp_x64/OSPPC.DLL" "$PREFIX/drive_c/windows/system32/sppc.dll"
cp "$old_ospp_x86/OSPPC.DLL" "$PREFIX/drive_c/windows/syswow64/sppc.dll"

wine_reg add 'HKLM\Software\Microsoft\OfficeSoftwareProtectionPlatform' /v Path /t REG_SZ /d 'C:\Program Files\Common Files\Microsoft Shared\OfficeSoftwareProtectionPlatform\' /f
wine_reg add 'HKLM\Software\Wow6432Node\Microsoft\OfficeSoftwareProtectionPlatform' /v Path /t REG_SZ /d 'C:\Program Files\Common Files\Microsoft Shared\OfficeSoftwareProtectionPlatform\' /f
wine_reg add 'HKLM\System\CurrentControlSet\Services\osppsvc' /v ImagePath /t REG_EXPAND_SZ /d 'C:\Program Files\Common Files\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPSVC.EXE' /f
wine_reg add 'HKLM\System\CurrentControlSet\Services\osppsvc' /v Type /t REG_DWORD /d 16 /f
wine_reg add 'HKLM\System\CurrentControlSet\Services\osppsvc' /v Start /t REG_DWORD /d 3 /f
wine_reg add 'HKCU\Software\Wine\DllOverrides' /v sppc /t REG_SZ /d native,builtin /f
