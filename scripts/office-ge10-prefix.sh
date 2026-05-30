#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RUNTIME_ROOT="${RUNTIME_ROOT:-/home/mars-user/office-open-repro/valve-wine-ge10-install}"
WINEBIN="${WINEBIN:-$RUNTIME_ROOT/bin/wine}"
WINE64BIN="${WINE64BIN:-$RUNTIME_ROOT/bin/wine64}"
WINESERVER="${WINESERVER:-$RUNTIME_ROOT/bin/wineserver}"
PREFIX="${PREFIX:-/home/mars-user/.local/share/office-proton/compatdata/office-ge10-odt2002-wow64/pfx}"
ODT_SETUP="${ODT_SETUP:-/home/mars-user/office-odt/old-12624/setup.exe}"
OFFICE_XML="${OFFICE_XML:-$REPO_ROOT/config/office32-2002-excelonly.xml}"
OVERRIDES_REG="${OVERRIDES_REG:-$REPO_ROOT/scripts/overrides/cx235-office-overrides.reg}"
LOG_DIR="${LOG_DIR:-/home/mars-user/office-open-repro/logs-ge10-prefix}"
WINSCARD_STUB="${WINSCARD_STUB:-/home/mars-user/office-open-repro/WinSCard.dll}"

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

case "${1:-help}" in
  help)
    cat <<'EOF'
Usage:
  office-ge10-prefix.sh inspect
  office-ge10-prefix.sh init-prefix
  office-ge10-prefix.sh apply-overrides
  office-ge10-prefix.sh install-native-msxml6
  office-ge10-prefix.sh build-winscard-stub
  office-ge10-prefix.sh install-winscard-stub
  office-ge10-prefix.sh install-office
  office-ge10-prefix.sh materialize-msoxmlmf
  office-ge10-prefix.sh launch-excel
  office-ge10-prefix.sh tasklist
  office-ge10-prefix.sh kill

This drives the currently accepted non-CrossOver path: a WOW64 prefix using the
patched GE-Proton10-34 Wine build plus Office 32-bit SemiAnnual 2002 Excel-only
payload from the archived Office Deployment Tool.
EOF
    ;;
  inspect)
    echo "REPO_ROOT=$REPO_ROOT"
    echo "RUNTIME_ROOT=$RUNTIME_ROOT"
    echo "PREFIX=$PREFIX"
    echo "ODT_SETUP=$ODT_SETUP"
    echo "OFFICE_XML=$OFFICE_XML"
    echo "OVERRIDES_REG=$OVERRIDES_REG"
    echo "LOG_DIR=$LOG_DIR"
    "$WINEBIN" --version
    "$WINE64BIN" --version
    ;;
  init-prefix)
    echo "Initializing WOW64 prefix: $PREFIX"
    run_wine wineboot -u
    run_wine winecfg -v win7
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
  build-winscard-stub)
    echo "Building WinSCard stub: $WINSCARD_STUB"
    mkdir -p "$(dirname "$WINSCARD_STUB")"
    x86_64-w64-mingw32-gcc -shared -o "$WINSCARD_STUB" "$REPO_ROOT/proton-stubs/winscard_stub.c" -Wl,--out-implib,"$WINSCARD_STUB.a"
    ;;
  install-winscard-stub)
    if [[ ! -f "$WINSCARD_STUB" ]]; then
      "$0" build-winscard-stub
    fi
    install -m 644 "$WINSCARD_STUB" "$PREFIX/drive_c/windows/system32/WinSCard.dll"
    run_wine reg add 'HKCU\Software\Wine\DllOverrides' /v winscard /d native,builtin /f
    run_wineserver -w || true
    ;;
  install-office)
    ensure_log_dir
    xml_win="Z:${OFFICE_XML//\//\\}"
    echo "Installing Office with $ODT_SETUP"
    echo "Office XML: $OFFICE_XML"
    echo "Log: $LOG_DIR/install-office.log"
    run_wine "$ODT_SETUP" /configure "$xml_win" \
      >"$LOG_DIR/install-office.log" 2>&1
    ;;
  materialize-msoxmlmf)
    source="$PREFIX/drive_c/Program Files (x86)/Microsoft Office/root/vfs/ProgramFilesCommonX86/Microsoft Shared/OFFICE16/MSOXMLMF.DLL"
    target_dir="$PREFIX/drive_c/Program Files (x86)/Common Files/Microsoft Shared/ClickToRun"
    target="$target_dir/msoxmlmf.dll"
    if [[ ! -f "$source" ]]; then
      echo "missing source: $source" >&2
      exit 1
    fi
    mkdir -p "$target_dir"
    cp -f "$source" "$target"
    echo "Materialized $target"
    ;;
  launch-excel)
    run_wine "C:\\Program Files (x86)\\Microsoft Office\\root\\Office16\\EXCEL.EXE"
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
