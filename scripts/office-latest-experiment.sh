#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RUNTIME_ROOT="${RUNTIME_ROOT:-/home/mars-user/office-open-repro/valve-wine-ge10-install}"
WINEBIN="${WINEBIN:-$RUNTIME_ROOT/bin/wine}"
WINESERVER="${WINESERVER:-$RUNTIME_ROOT/bin/wineserver}"
PREFIX="${PREFIX:-/home/mars-user/.local/share/office-proton/compatdata/latest-officesetup-win10/pfx}"
WINDOWS_VERSION="${WINDOWS_VERSION:-win10}"
OFFICE_SETUP="${OFFICE_SETUP:-/home/mars-user/OfficeSetup.exe}"
ODT_SETUP="${ODT_SETUP:-/home/mars-user/office-odt/setup.exe}"
OFFICE_XML="${OFFICE_XML:-$REPO_ROOT/config/office-latest-excelonly-current.xml}"
OVERRIDES_REG="${OVERRIDES_REG:-$REPO_ROOT/scripts/overrides/cx235-office-overrides.reg}"
LOG_DIR="${LOG_DIR:-/home/mars-user/office-open-repro/logs-latest-officesetup-win10}"
WINSCARD_STUB="${WINSCARD_STUB:-/home/mars-user/office-open-repro/WinSCard.dll}"
EXCEL_EXE="${EXCEL_EXE:-C:\\Program Files (x86)\\Microsoft Office\\root\\Office16\\EXCEL.EXE}"
VIRTUAL_DESKTOP="${VIRTUAL_DESKTOP:-office-latest,1200x900}"
OFFICE16_UNIX="${OFFICE16_UNIX:-$PREFIX/drive_c/Program Files (x86)/Microsoft Office/root/Office16}"
COREMESSAGING_ALIAS="${COREMESSAGING_ALIAS:-$PREFIX/drive_c/windows/syswow64/CoreMessagingXP.dll}"
FRAMEWORKUDK_TARGET="${FRAMEWORKUDK_TARGET:-$PREFIX/drive_c/windows/syswow64/Microsoft.Internal.FrameworkUdk.dll}"

wine_env() {
  unset CX_ROOT CX_BOTTLE CX_BOTTLE_PATH CX_MANAGED_BOTTLE_PATH WINEDLLPATH
  export WINEARCH=win64
  export PATH="$RUNTIME_ROOT/bin:$PATH"
  export LD_LIBRARY_PATH="$RUNTIME_ROOT/lib:$RUNTIME_ROOT/lib/wine${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
  export DISPLAY="${DISPLAY:-:0}"
}

run_wine() {
  wine_env
  WINEPREFIX="$PREFIX" "$WINEBIN" "$@"
}

run_wineserver() {
  wine_env
  WINEPREFIX="$PREFIX" "$WINESERVER" "$@"
}

ensure_log_dir() {
  mkdir -p "$LOG_DIR"
}

xml_windows_path() {
  printf 'Z:%s' "${OFFICE_XML//\//\\}"
}

case "${1:-help}" in
  help)
    cat <<'EOF'
Usage:
  office-latest-experiment.sh inspect
  office-latest-experiment.sh init-prefix
  office-latest-experiment.sh apply-overrides
  office-latest-experiment.sh install-native-msxml6
  office-latest-experiment.sh install-winscard-stub
  office-latest-experiment.sh run-officesetup
  office-latest-experiment.sh run-latest-odt
  office-latest-experiment.sh prepare-current-launch
  office-latest-experiment.sh current-launch-status
  office-latest-experiment.sh clear-excel-resiliency
  office-latest-experiment.sh launch-excel
  office-latest-experiment.sh launch-excel-log
  office-latest-experiment.sh launch-excel-x11
  office-latest-experiment.sh launch-excel-x11-log
  office-latest-experiment.sh tasklist
  office-latest-experiment.sh kill

Defaults are intentionally experimental and separate from the known-good
Office 16.0.12527.21416 prefix.
EOF
    ;;
  inspect)
    echo "REPO_ROOT=$REPO_ROOT"
    echo "RUNTIME_ROOT=$RUNTIME_ROOT"
    echo "PREFIX=$PREFIX"
    echo "WINDOWS_VERSION=$WINDOWS_VERSION"
    echo "OFFICE_SETUP=$OFFICE_SETUP"
    echo "ODT_SETUP=$ODT_SETUP"
    echo "OFFICE_XML=$OFFICE_XML"
    echo "OVERRIDES_REG=$OVERRIDES_REG"
    echo "LOG_DIR=$LOG_DIR"
    "$WINEBIN" --version
    ;;
  init-prefix)
    echo "Initializing experimental WOW64 prefix: $PREFIX ($WINDOWS_VERSION)"
    mkdir -p "$PREFIX"
    run_wine wineboot -u
    run_wine winecfg -v "$WINDOWS_VERSION"
    run_wineserver -w || true
    ;;
  apply-overrides)
    echo "Applying Office DLL overrides: $OVERRIDES_REG"
    run_wine regedit "$OVERRIDES_REG"
    run_wineserver -w || true
    ;;
  install-native-msxml6)
    echo "Installing native msxml6 into: $PREFIX"
    wine_env
    WINEPREFIX="$PREFIX" WINE="$WINEBIN" WINESERVER="$WINESERVER" winetricks -q msxml6
    run_wineserver -w || true
    ;;
  install-winscard-stub)
    if [[ ! -f "$WINSCARD_STUB" ]]; then
      x86_64-w64-mingw32-gcc -shared -o "$WINSCARD_STUB" "$REPO_ROOT/proton-stubs/winscard_stub.c" -Wl,--out-implib,"$WINSCARD_STUB.a"
    fi
    install -m 644 "$WINSCARD_STUB" "$PREFIX/drive_c/windows/system32/WinSCard.dll"
    run_wine reg add 'HKCU\Software\Wine\DllOverrides' /v winscard /d native,builtin /f
    run_wineserver -w || true
    ;;
  run-officesetup)
    ensure_log_dir
    echo "Running current OfficeSetup.exe"
    echo "Log: $LOG_DIR/officesetup.log"
    run_wine "$OFFICE_SETUP" >"$LOG_DIR/officesetup.log" 2>&1
    ;;
  run-latest-odt)
    ensure_log_dir
    xml_win="$(xml_windows_path)"
    echo "Running latest/current ODT setup with $OFFICE_XML"
    echo "Log: $LOG_DIR/latest-odt-configure.log"
    run_wine "$ODT_SETUP" /configure "$xml_win" >"$LOG_DIR/latest-odt-configure.log" 2>&1
    ;;
  prepare-current-launch)
    echo "Preparing latest/current Excel prefix launch materialization"
    if [[ ! -f "$RUNTIME_ROOT/lib/wine/i386-windows/coremessaging.dll" ]]; then
      echo "missing runtime coremessaging.dll" >&2
      exit 1
    fi
    if [[ ! -f "$OFFICE16_UNIX/WinAppSDK/Microsoft.Internal.FrameworkUdk.dll" ]]; then
      echo "missing Office WinAppSDK FrameworkUdk DLL: $OFFICE16_UNIX/WinAppSDK/Microsoft.Internal.FrameworkUdk.dll" >&2
      exit 1
    fi

    install -m 644 "$RUNTIME_ROOT/lib/wine/i386-windows/coremessaging.dll" "$COREMESSAGING_ALIAS"
    install -m 644 "$OFFICE16_UNIX/WinAppSDK/Microsoft.Internal.FrameworkUdk.dll" "$FRAMEWORKUDK_TARGET"

    run_wine reg add 'HKLM\Software\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.UI.Dispatching.DispatcherQueue' /v DllPath /t REG_SZ /d 'C:\windows\system32\coremessaging.dll' /f
    run_wine reg add 'HKLM\Software\Wow6432Node\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.UI.Dispatching.DispatcherQueue' /v DllPath /t REG_SZ /d 'C:\windows\system32\coremessaging.dll' /f
    run_wine reg add 'HKLM\Software\Wow6432Node\Microsoft\WindowsRuntime\ActivatableClassId\Windows.System.DispatcherQueue' /v DllPath /t REG_SZ /d 'C:\windows\system32\coremessaging.dll' /f
    run_wine reg add 'HKLM\Software\Microsoft\WindowsRuntime\ActivatableClassId\Windows.System.Profile.SharedModeSettings' /v DllPath /t REG_SZ /d 'C:\windows\system32\windows.system.profile.systemmanufacturers.dll' /f
    run_wine reg add 'HKLM\Software\Wow6432Node\Microsoft\WindowsRuntime\ActivatableClassId\Windows.System.Profile.SharedModeSettings' /v DllPath /t REG_SZ /d 'C:\windows\system32\windows.system.profile.systemmanufacturers.dll' /f
    run_wineserver -w || true
    ;;
  current-launch-status)
    echo "Prefix: $PREFIX"
    echo "Office16: $OFFICE16_UNIX"
    echo
    if [[ -f "$COREMESSAGING_ALIAS" ]]; then
      sha256sum "$COREMESSAGING_ALIAS" "$RUNTIME_ROOT/lib/wine/i386-windows/coremessaging.dll"
    else
      echo "missing: $COREMESSAGING_ALIAS"
    fi
    if [[ -f "$FRAMEWORKUDK_TARGET" && -f "$OFFICE16_UNIX/WinAppSDK/Microsoft.Internal.FrameworkUdk.dll" ]]; then
      sha256sum "$FRAMEWORKUDK_TARGET" "$OFFICE16_UNIX/WinAppSDK/Microsoft.Internal.FrameworkUdk.dll"
    else
      echo "missing FrameworkUdk materialization"
    fi
    echo
    run_wine reg query 'HKLM\Software\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.UI.Dispatching.DispatcherQueue' /v DllPath || true
    run_wine reg query 'HKLM\Software\Wow6432Node\Microsoft\WindowsRuntime\ActivatableClassId\Microsoft.UI.Dispatching.DispatcherQueue' /v DllPath || true
    run_wine reg query 'HKLM\Software\Wow6432Node\Microsoft\WindowsRuntime\ActivatableClassId\Windows.System.DispatcherQueue' /v DllPath || true
    run_wine reg query 'HKLM\Software\Microsoft\WindowsRuntime\ActivatableClassId\Windows.System.Profile.SharedModeSettings' /v DllPath || true
    run_wine reg query 'HKLM\Software\Wow6432Node\Microsoft\WindowsRuntime\ActivatableClassId\Windows.System.Profile.SharedModeSettings' /v DllPath || true
    ;;
  launch-excel)
    run_wine "$EXCEL_EXE"
    ;;
  launch-excel-log)
    ensure_log_dir
    echo "Launching Excel"
    echo "Log: $LOG_DIR/excel-launch.log"
    run_wine "$EXCEL_EXE" >"$LOG_DIR/excel-launch.log" 2>&1
    ;;
  clear-excel-resiliency)
    echo "Clearing Excel crash/Safe Mode resiliency markers"
    run_wine reg delete 'HKCU\Software\Microsoft\Office\16.0\Excel\Resiliency' /f || true
    run_wine reg delete 'HKCU\Software\Microsoft\Office\16.0\Excel' /v ExcelPreviousSessionId /f || true
    run_wine reg delete 'HKCU\Software\Microsoft\Office\16.0\Excel' /v ExcelPreviousSessionVersion /f || true
    run_wineserver -w || true
    ;;
  launch-excel-x11)
    wine_env
    unset WAYLAND_DISPLAY
    export OFFICE_SPP_NATIVE_POLICY_ERRORS="${OFFICE_SPP_NATIVE_POLICY_ERRORS:-1}"
    WINEPREFIX="$PREFIX" "$WINEBIN" explorer "/desktop=$VIRTUAL_DESKTOP" "$EXCEL_EXE"
    ;;
  launch-excel-x11-log)
    ensure_log_dir
    wine_env
    unset WAYLAND_DISPLAY
    export OFFICE_SPP_NATIVE_POLICY_ERRORS="${OFFICE_SPP_NATIVE_POLICY_ERRORS:-1}"
    export WINEDEBUG="${WINEDEBUG:-+dwmapi,+d2d,+messaging,+onlineid,fixme+combase,fixme+wintypes,err+ole,+loaddll}"
    echo "Launching Excel in X11 Wine desktop: $VIRTUAL_DESKTOP"
    echo "Log: $LOG_DIR/excel-x11-launch.log"
    WINEPREFIX="$PREFIX" "$WINEBIN" explorer "/desktop=$VIRTUAL_DESKTOP" "$EXCEL_EXE" >"$LOG_DIR/excel-x11-launch.log" 2>&1
    ;;
  tasklist)
    run_wine tasklist
    ;;
  kill)
    run_wineserver -k || true
    ;;
  *)
    echo "unknown command: $1" >&2
    exit 64
    ;;
esac
