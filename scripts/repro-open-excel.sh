#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/home/mars-user/office-open-repro}"
OFFICE_ODT="${OFFICE_ODT:-/home/mars-user/office-odt/old-12624/setup.exe}"
OFFICE_XML="${OFFICE_XML:-/home/mars-user/office-odt/install-office32-2002-excelonly.xml}"
PREFIX="${PREFIX:-/home/mars-user/.local/share/office-open-repro/prefix-clean}"
COPIED_PREFIX="${COPIED_PREFIX:-/home/mars-user/.local/share/office-open-repro/prefix-from-cx235}"
WINE_ROOT="${WINE_ROOT:-$ROOT/wine-cx235-install}"
WINEBIN="${WINEBIN:-$WINE_ROOT/bin/wine}"
WINE_SERVER="${WINE_SERVER:-$WINE_ROOT/bin/wineserver}"
LOG_DIR="${LOG_DIR:-/home/mars-user/office-open-repro/logs}"
OVERRIDES_REG="${OVERRIDES_REG:-$ROOT/cx235-office-overrides.reg}"

wine_env() {
  unset CX_ROOT CX_BOTTLE CX_BOTTLE_PATH CX_MANAGED_BOTTLE_PATH WINEDLLPATH
  export WINEARCH=win32
  export PATH="$WINE_ROOT/bin:$PATH"
  export LD_LIBRARY_PATH="$WINE_ROOT/lib:$WINE_ROOT/lib/wine${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
  export DISPLAY="${DISPLAY:-:0}"
}

run_wine() {
  local prefix="$1"
  shift
  wine_env
  WINEPREFIX="$prefix" "$WINEBIN" "$@"
}

run_wineserver() {
  local prefix="$1"
  shift
  wine_env
  WINEPREFIX="$prefix" "$WINE_SERVER" "$@"
}

ensure_log_dir() {
  mkdir -p "$LOG_DIR"
}

case "${1:-help}" in
  help)
    cat <<'EOF'
Usage:
  repro-open-excel.sh inspect
  repro-open-excel.sh show-candidate-patches
  repro-open-excel.sh launch-copied-prefix
  repro-open-excel.sh launch-copied-prefix-terminal
  repro-open-excel.sh init-clean-prefix
  repro-open-excel.sh apply-cx235-overrides
  repro-open-excel.sh install-native-msxml6
  repro-open-excel.sh install-clean-prefix
  repro-open-excel.sh materialize-msoxmlmf
  repro-open-excel.sh launch-clean-prefix
  repro-open-excel.sh tasklist-clean
  repro-open-excel.sh kill-clean

This script drives the open-source Wine reproduction. The currently verified
runtime is the locally built CodeWeavers 23.5 Wine source tree installed at
/home/mars-user/office-open-repro/wine-cx235-install.
EOF
    ;;
  inspect)
    echo "ROOT=$ROOT"
    echo "OFFICE_ODT=$OFFICE_ODT"
    echo "OFFICE_XML=$OFFICE_XML"
    echo "PREFIX=$PREFIX"
    echo "COPIED_PREFIX=$COPIED_PREFIX"
    echo "WINE_ROOT=$WINE_ROOT"
    echo "WINEBIN=$WINEBIN"
    wine_env
    "$WINEBIN" --version || true
    file "$WINEBIN" "$WINE_ROOT/lib/wine/i386-unix/ntdll.dll.so" || true
    ;;
  show-candidate-patches)
    echo "Candidate CrossOver-vs-upstream Wine 8.0.1 diffs:"
    ls -1 "$ROOT"/diffs/dlls-rpcrt4-rpc_transport.c.diff \
          "$ROOT"/diffs/dlls-ntdll-unix-file.c.diff \
          "$ROOT"/diffs/dlls-ntdll-unix-loader.c.diff \
          "$ROOT"/diffs/dlls-ntdll-ntdll.spec.diff \
          "$ROOT"/diffs/dlls-wow64-file.c.diff \
          "$ROOT"/diffs/dlls-wow64-syscall.h.diff \
          "$ROOT"/diffs/dlls-kernelbase-file.c.diff
    echo
    grep -nEi 'CXHACK 14391|ClickToRun|__wine_rpc_NtReadFile|CXHACK 13427|OfficeClickToRun' "$ROOT"/diffs/*.diff || true
    ;;
  launch-copied-prefix)
    run_wine "$COPIED_PREFIX" "C:\\Program Files\\Microsoft Office\\root\\Office16\\EXCEL.EXE"
    ;;
  launch-copied-prefix-terminal)
    exec env XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}" DISPLAY="${DISPLAY:-:0}" \
      foot bash -lc "'$0' launch-copied-prefix; status=\$?; echo; echo \"Excel exited with status \$status\"; echo \"Press Enter to close this terminal.\"; read _"
    ;;
  init-clean-prefix)
    echo "Initializing clean prefix: $PREFIX"
    run_wine "$PREFIX" wineboot -u
    run_wine "$PREFIX" winecfg -v win7
    run_wineserver "$PREFIX" -w || true
    ;;
  apply-cx235-overrides)
    echo "Applying Office DLL overrides: $OVERRIDES_REG"
    run_wine "$PREFIX" regedit "$OVERRIDES_REG"
    run_wineserver "$PREFIX" -w || true
    ;;
  install-native-msxml6)
    echo "Installing native msxml6 into: $PREFIX"
    wine_env
    WINEPREFIX="$PREFIX" WINE="$WINEBIN" WINESERVER="$WINE_SERVER" winetricks -q msxml6
    run_wineserver "$PREFIX" -w || true
    ;;
  install-clean-prefix)
    ensure_log_dir
    echo "Installing Office into clean prefix: $PREFIX"
    echo "Log: $LOG_DIR/install-clean-prefix.log"
    run_wine "$PREFIX" "$OFFICE_ODT" /configure "Z:\\home\\mars-user\\office-odt\\install-office32-2002-excelonly.xml" \
      >"$LOG_DIR/install-clean-prefix.log" 2>&1
    ;;
  materialize-msoxmlmf)
    source="$PREFIX/drive_c/Program Files/Microsoft Office/root/vfs/ProgramFilesCommonX86/Microsoft Shared/OFFICE16/MSOXMLMF.DLL"
    target_dir="$PREFIX/drive_c/Program Files/Common Files/Microsoft Shared/ClickToRun"
    target="$target_dir/msoxmlmf.dll"
    if [[ ! -f "$source" ]]; then
      echo "missing source: $source" >&2
      exit 1
    fi
    mkdir -p "$target_dir"
    cp -f "$source" "$target"
    echo "Materialized $target"
    ;;
  launch-clean-prefix)
    run_wine "$PREFIX" "C:\\Program Files\\Microsoft Office\\root\\Office16\\EXCEL.EXE"
    ;;
  tasklist-clean)
    run_wine "$PREFIX" tasklist
    ;;
  kill-clean)
    run_wineserver "$PREFIX" -k || true
    ;;
  *)
    echo "unknown command: $1" >&2
    exit 64
    ;;
esac
