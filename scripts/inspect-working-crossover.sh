#!/usr/bin/env bash
set -euo pipefail

CX_ROOT="${CX_ROOT:-/home/mars-user/crossover-23.5/opt/cxoffice}"
CX_BOTTLE_PATH="${CX_BOTTLE_PATH:-/home/mars-user/.cxoffice235}"
BOTTLE="${BOTTLE:-office365-cx235-win7c}"
PREFIX="$CX_BOTTLE_PATH/$BOTTLE"

echo "== CrossOver/Wine runtime =="
"$CX_ROOT/bin/wine" --version || true
strings "$CX_ROOT/lib/wine/i386-unix/ntdll.so" | grep -E 'wine-[0-9]' | head -n 1 || true

echo
echo "== Bottle config =="
grep -E '"(Template|WineArch|Version|BottleID)"' "$PREFIX/cxbottle.conf" || true

echo
echo "== Office binaries =="
find "$PREFIX/drive_c/Program Files/Microsoft Office/root" \
  -maxdepth 4 \
  \( -iname 'EXCEL.EXE' -o -iname 'AppVLP.exe' -o -iname 'OfficeClickToRun.exe' -o -iname 'AppvIsvSubsystems32.dll' -o -iname 'C2R32.dll' -o -iname 'JitV.dll' \) \
  -print | sort

echo
echo "== AppV / ClickToRun registry anchors =="
for pattern in \
  '[Software\\Microsoft\\AppVISV]' \
  '[Software\\Microsoft\\AppV\\Client\\Packages' \
  '[Software\\Microsoft\\Office\\16.0\\ClickToRunStore\\Applications]' \
  '[Software\\Microsoft\\Office\\16.0\\ClickToRunStore\\Packages' \
  '[Software\\Microsoft\\Office\\ClickToRun\\AppVMachineRegistryStore'
do
  grep -nF "$pattern" "$PREFIX/system.reg" | head -n 10 || true
done

echo
echo "== DLL override block =="
awk '
  /^\[Software\\\\Wine\\\\DllOverrides\]/ {show=1}
  show {print}
  show && /^$/ {exit}
' "$PREFIX/user.reg" | head -n 80 || true

echo
echo "== Live Office processes =="
ps -u "${USER:-mars-user}" -o pid,ppid,stat,etime,pcpu,pmem,comm,args \
  | grep -Ei 'EXCEL|OfficeClick|AppV|wineserver|cxoffice' \
  | grep -v grep || true
