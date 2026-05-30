# Latest Office OSPP/SPP Findings

Checkpoint: 2026-05-30 20:54 UTC

This documents the current/latest Office path, not the known-good archived
Office `16.0.12527.21416` path.

## Current State

- Runtime:
  `/home/mars-user/office-open-repro/valve-wine-ge10-install`
- Prefix:
  `/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx`
- Prefix architecture: WOW64, `WINEARCH=win64`
- Windows version: `win10`
- Office payload: Current Channel, 32-bit Excel-only, `16.0.20026.20112`
- Launch command:

```bash
PREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-latest-odt-current32-win10 \
/home/mars-user/excel-on-linux/scripts/office-latest-experiment.sh launch-excel-log
```

## Evidence

The current x86 Office manifest contains OfficeSoftwareProtectionPlatform files
only under `ProgramFilesCommonX64`. It does not list a
`ProgramFilesCommonX86\Microsoft Shared\OfficeSoftwareProtectionPlatform`
payload.

Command used:

```bash
strings -el -n 4 \
  /home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10/pfx/drive_c/ProgramData/Microsoft/ClickToRun/ProductReleases/3BAE83F9-3005-46F6-B350-D3C956657002/x-none.16/stream.x86.x-none.man.dat \
  | grep -i 'OfficeSoftwareProtectionPlatform\|OSPPC\|OSPPSVC\|OSPPOBJS\|OSPPCEXT'
```

Relevant output:

```text
root\vfs\ProgramFilesCommonX64\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPC.DLL
root\vfs\ProgramFilesCommonX64\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPOBJS.DLL
root\vfs\ProgramFilesCommonX64\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPCEXT.DLL
root\vfs\ProgramFilesCommonX64\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPSVC.EXE
```

The materialized latest diagnostic has:

```text
C:\Program Files\Common Files\Microsoft Shared\OfficeSoftwareProtectionPlatform\OSPPC.DLL
C:\Program Files\Common Files\Microsoft Shared\ClickToRun\0\osppc.dll
C:\windows\system32\sppc.dll
```

The 32-bit `C:\windows\syswow64\sppc.dll` currently comes from the older
known-good Office OSPPC because no current x86 OSPPC was found in the latest
install payload.

## What Changed Behavior

Without native OSPP/SPP, latest Excel emits Office repair event `702061`:

```text
Microsoft Excel
We're sorry, but Excel has run into an error...
version 16.0.20026.20112
token 8qeyi
```

Materializing latest x64 OSPP and adding `ClickToRun\0\osppc.dll` fixed an
earlier load failure but did not clear the repair event by itself.

Forcing `sppc=native,builtin` and replacing `system32/syswow64\sppc.dll` with
native Office OSPPC made `OSPPSVC.EXE` run and cleared `702061`. Excel reached:

```text
Microsoft respects your privacy
Excel (Non-Commercial Use) (Unlicensed Product)
```

Screenshots:

- `public/latest-current-excel-after-clicktorun-osppc.png`
- `public/latest-current-excel-privacy-dialog-native-osppc-sppc.png`

## Reproduction Helper

Diagnostic helper:

```bash
/home/mars-user/excel-on-linux/scripts/experiments/latest-native-ospp-diagnostic.sh status
/home/mars-user/excel-on-linux/scripts/experiments/latest-native-ospp-diagnostic.sh apply
/home/mars-user/excel-on-linux/scripts/experiments/latest-native-ospp-diagnostic.sh restore
```

This helper is intentionally labeled diagnostic. It proves the blocker is in
Wine's SPP/OSPP behavior, but it is not the final open-runtime implementation
because it borrows native Office protection DLLs.

## Next Engineering Target

The next open-runtime task is to replace the native `sppc` dependency with a
Wine implementation that behaves enough like Office OSPP/SPP for this current
build:

- materialize or emulate the OSPP service/path expectations;
- satisfy Click-to-Run's `osppc.dll` lookup;
- implement the SPP authentication/result path behind Excel's 288-byte
  `SLSetAuthenticationData` challenge;
- preserve the latest/current Excel path and keep the older archived Office
  prefix untouched.

Native OSPPC exports 55 `SL*`/`SLp*` entry points. The current Wine `sppc`
worktree implements the functions Excel has reached so far, but the saved logs
do not contain the full 288-byte authentication challenge anymore. Only the
first bytes were preserved in `progress.md`:

```text
20 01 00 00 01 00 00 00 00 00 01 00 0c 01 00 00
01 02 00 00 10 66 00 00 00 a4 00 00 c1 9c ef 06 ...
```

Do not implement the final auth response from this partial blob. The next clean
step is to capture the full `SLSetAuthenticationData` payload again in a
disposable restored/builtin-SPP test prefix, then feed those bytes to native
OSPP with a small probe to observe the real `SLGetAuthenticationResult` output.

## Auth Challenge Capture

Checkpoint: 2026-05-30 21:23 UTC

Disposable prefix:

```text
/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx
```

Capture command:

```bash
timeout 45s env WINEDEBUG=fixme+slc \
  PREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
  LOG_DIR=/home/mars-user/office-open-repro/logs-latest-authprobe \
  /home/mars-user/excel-on-linux/scripts/office-latest-experiment.sh launch-excel-log
```

Captured full 288-byte `SLSetAuthenticationData` payload:

```text
0000: 20 01 00 00 01 00 00 00 00 00 01 00 0c 01 00 00 01 02 00 00 10 66 00 00 00 a4 00 00 08 31 ea e6
0020: e3 fd 70 05 4e c7 07 25 01 62 24 c4 66 91 3a 84 49 47 b8 4c c6 43 0b 0d f5 84 95 a0 bc 1d 2c bc
0040: 8c 04 0c 1f 64 09 1b 11 06 db 58 fe 18 5b 41 38 0d 6e 16 7e ba ab f1 5f ee 2b 7b 76 ea 88 fd ae
0060: c4 bf ba 21 eb b8 60 6d 1f f3 53 67 3b 93 ff b2 c5 92 73 79 b3 79 1d 80 55 cf 5d 9b fd d9 93 58
0080: 3d 51 81 f6 d7 f5 e8 74 77 5e fe b3 6b 4a a1 15 c6 39 8b b3 8a 33 ad 58 c5 9a ee c1 77 62 1a f1
00a0: f4 e6 86 52 fc a9 20 89 cd 7a 46 58 02 16 3c c8 ee c9 33 45 21 f2 04 38 5a cc 41 46 bf 44 f9 a3
00c0: bc be 35 94 3e 49 d2 18 f6 88 8d 26 cf fc 5e 15 28 8a 1c b7 f1 64 de c0 d8 c4 48 40 fc 0d 27 2c
00e0: ae 96 7f b7 80 e5 42 87 df e3 d0 ab 30 6a bd 55 5c 9c 56 df 3f 8b ec 33 b2 54 63 94 65 29 08 0d
0100: 4a 15 55 2a 26 f3 f1 00 68 ec 98 ae e0 a1 42 e2 0e 0d 6f ac 91 08 d8 5f c2 c9 25 86 55 00 41 00
```

Native result probe:

```bash
i686-w64-mingw32-gcc -Wall -Wextra -O2 \
  -o tools/sppc-auth-probe32.exe tools/sppc-auth-probe.c

WINEPREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
WINEARCH=win64 \
PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/bin:$PATH \
LD_LIBRARY_PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/lib:/home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine \
/home/mars-user/office-open-repro/valve-wine-ge10-install/bin/wine \
  /home/mars-user/excel-on-linux/tools/sppc-auth-probe32.exe
```

Observed native probe result:

```text
challenge_size=288
SLOpen hr=0xc0020012 handle=00000000
err:rpc:RpcAssoc_BindConnection syntax {9435cc56-1d9c-4924-ac7d-b60a2c3520e1}, 1.0 not supported
```

That means standalone native OSPPC wants the OSPP RPC service protocol, and
Wine does not support that RPC interface yet. A diagnostic Wine patch that made
`SLOpen` return `0xc0020012` still hit Excel repair `702061`, so the current
fix is not simply copying native's standalone failure code.

The native OSPP binaries expose the local RPC transport details:

```text
ncalrpc
OSPPCTransportEndpoint-00001
SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform
S-1-5-20\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform\Policies
```

`OSPPSVC.EXE` imports the RPC server side:

```text
RpcServerUseProtseqEpW
RpcServerRegisterIfEx
RpcServerListen
NdrServerCall2
NdrServerCallAll
```

Next likely implementation path: trace or shim the `ncalrpc`
`OSPPCTransportEndpoint-00001` interface `{9435cc56-1d9c-4924-ac7d-b60a2c3520e1}`
well enough for Office's `SL*` calls, or teach builtin Wine `sppc` the
equivalent service-backed behavior without loading native OSPPC.

## RPC Lifetime Trace

Checkpoint: 2026-05-30 21:40 UTC

Trace command:

```bash
timeout 25s env WINEDEBUG=+rpc,+ndr,+module \
  WINEPREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
  WINEARCH=win64 \
  PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/bin:$PATH \
  LD_LIBRARY_PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/lib:/home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine \
  /home/mars-user/office-open-repro/valve-wine-ge10-install/bin/wine \
    /home/mars-user/excel-on-linux/tools/sppc-auth-probe32.exe \
  > /home/mars-user/office-open-repro/logs-latest-authprobe/sppc-auth-probe-rpc.log 2>&1
```

The service does register the OSPP interface:

```text
RpcServerUseProtseqEpW (L"ncalrpc",100,L"OSPPCTransportEndpoint-00001",...)
RpcServerRegisterIf3 interface id: {9435cc56-1d9c-4924-ac7d-b60a2c3520e1} 1.0
dispatch table count: 4
```

The first native client bind is accepted:

```text
process_bind_packet_no_send accepting bind request on connection ... for {9435cc56-1d9c-4924-ac7d-b60a2c3520e1}
```

Then OSPPSVC reports `0x80070002` and unregisters the interface:

```text
ReportEventW event string[0]: L"0x80070002"
ReportEventW event string[1]: L"15.0.169.500"
RpcServerUnregisterIf ... ({9435cc56-1d9c-4924-ac7d-b60a2c3520e1})
```

Later client calls then fail because the interface is gone:

```text
process_request_packet interface {9435cc56-1d9c-4924-ac7d-b60a2c3520e1} no longer registered
```

An additional trace with `+file,+reg,+rpc` shows OSPPSVC checks:

```text
C:\ProgramData\Microsoft\OfficeSoftwareProtectionPlatform\
HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform
HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform\data
```

but no definitive missing `tokens.dat` open was observed before the event.
Copying the older known-good `tokens.dat` and `Cache\cache.dat` into the
disposable authprobe prefix did not change the outcome: OSPPSVC still reported
`0x80070002`, unregistered `{9435cc56...}`, and native `SLOpen` returned
`0xc0020012`.

The next useful experiment is to identify what OSPPSVC's first RPC method
expects and why it posts `0x80070002`. In the trace, native OSPP uses four
interface methods; the probe reaches proc nums `0`, `1`, and `2`, while the
service unregisters immediately after handling the first request.

## OSPP Event Stack

Checkpoint: 2026-05-30 21:58 UTC

Added a targeted `advapi32.ReportEventW` stack trace for the OSPPSVC event:

```text
dwEventID=0xc00003e9
event string[0]=0x80070002
event string[1]=15.0.169.500
```

Build/copy command:

```bash
make -C /home/mars-user/office-open-repro/build/valve-wine-ge10-office-x64 \
  dlls/advapi32/x86_64-windows/advapi32.dll
cp /home/mars-user/office-open-repro/build/valve-wine-ge10-office-x64/dlls/advapi32/x86_64-windows/advapi32.dll \
  /home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine/x86_64-windows/advapi32.dll
```

Probe command:

```bash
timeout 30s env WINEDEBUG=fixme+advapi \
  WINEPREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
  WINEARCH=win64 \
  PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/bin:$PATH \
  LD_LIBRARY_PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/lib:/home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine \
  /home/mars-user/office-open-repro/valve-wine-ge10-install/bin/wine \
    /home/mars-user/excel-on-linux/tools/sppc-auth-probe32.exe \
  > /home/mars-user/office-open-repro/logs-latest-authprobe/sppc-auth-probe-ospp-event-stack.log 2>&1
```

Observed:

```text
ReportEventW tracing Office Software Protection Platform 0x80070002 event stack.
ReportEventW ospp event stack hash 0xfdbd7b16, frames 11.
frame[0] = 00006FFFFF24CD5F  advapi32.dll +0x1cd5f
frame[1] = 00000001000A739F  OSPPSVC.EXE +0xa739f
frame[2] = 0000000100058555  OSPPSVC.EXE +0x58555
frame[3] = 00000001000583F2  OSPPSVC.EXE +0x583f2
frame[4] = 000000010005AF85  OSPPSVC.EXE +0x5af85
```

`OSPPSVC.EXE` has `ImageBase=0x100000000`; the first native return address is
immediately after a call through the import table in the OSPPSVC event-reporting
path. This narrows the failure to native service initialization / SPP data
startup, not the client-side 32-bit `OSPPC.DLL` load itself.

In this run, `SLOpen` returned success and the next call failed:

```text
SLOpen hr=0x00000000 handle=00356d10
SLSetAuthenticationData hr=0xc0020012
```

That is a useful correction to the earlier standalone probe result: the service
can come up far enough to open a handle, but it posts `0x80070002` and later
RPC calls fault with `0x1c010003` / `0xc0020012`. Next target: trace the first
server-side OSPP proc after `SLOpen` with enough parameter detail to understand
what SPP data or service state is missing.

## Post-Open RPC Trace

Checkpoint: 2026-05-30 22:04 UTC

Trace command:

```bash
timeout 30s env WINEDEBUG=+rpc,+ndr,fixme+advapi \
  WINEPREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
  WINEARCH=win64 \
  PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/bin:$PATH \
  LD_LIBRARY_PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/lib:/home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine \
  /home/mars-user/office-open-repro/valve-wine-ge10-install/bin/wine \
    /home/mars-user/excel-on-linux/tools/sppc-auth-probe32.exe \
  > /home/mars-user/office-open-repro/logs-latest-authprobe/sppc-auth-probe-postopen-rpc.log 2>&1
```

Relevant sequence:

```text
RpcServerRegisterIf3 interface id: {9435cc56-1d9c-4924-ac7d-b60a2c3520e1} 1.0
NdrpClientCall2 proc num: 0
process_bind_packet_no_send accepting bind request ... {9435cc56...}
ReportEventW ... 0xc00003e9 ... "0x80070002" / "15.0.169.500"
NdrStubCall2 version 0x60001 ... stack size 18, format 000000010003FC4C
RpcServerUnregisterIf ... ({9435cc56-1d9c-4924-ac7d-b60a2c3520e1})
SLOpen hr=0x00000000 handle=00356d18
NdrpClientCall2 proc num: 2
process_request_packet interface {9435cc56...} no longer registered
SLSetAuthenticationData hr=0xc0020012
NdrpClientCall2 proc num: 1
process_request_packet interface {9435cc56...} no longer registered
```

Interpretation: OSPPC proc `0` is the open path. It returns a valid handle even
after OSPPSVC logs `0x80070002`, but the service unregisters the OSPP interface
before proc `2` (`SLSetAuthenticationData`) and proc `1`
(`SLGetAuthenticationResult`/close-path in the probe sequence) can complete.

This makes the next implementation target narrower: either prevent the native
service from tearing down by satisfying its startup data expectation, or stop
depending on native OSPP and implement enough of proc `0/2/1` behavior in
Wine's builtin `sppc` for Excel's auth challenge.

## OSPP Plugin Registry Skeleton Test

Checkpoint: 2026-05-30 22:18 UTC

Compared the known-good Office 16.0.12527 prefix against the latest authprobe
clone and found that the known-good prefix has a populated
`HKLM\Software\Microsoft\OfficeSoftwareProtectionPlatform` tree:

- root values such as `InactivityShutdownDelay`, `ServiceSessionId`, and
  `UserOperations`
- `data` directory key `8fcc4cd6-36bc-4eb9-bece-10de1b3b8a45`
- plugin module `ba38975c-7786-44bc-b924-147c77920328`
- plugin object registrations for SPP algorithms, payload handlers, state
  collector, task scheduler, and KMS renewal objects

Added that registry skeleton to the disposable latest authprobe prefix and
verified it was visible via:

```bash
env WINEPREFIX=/home/mars-user/.local/share/office-proton/compatdata/latest-odt-current32-win10-authprobe/pfx \
  WINEARCH=win64 \
  PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/bin:$PATH \
  LD_LIBRARY_PATH=/home/mars-user/office-open-repro/valve-wine-ge10-install/lib:/home/mars-user/office-open-repro/valve-wine-ge10-install/lib/wine \
  /home/mars-user/office-open-repro/valve-wine-ge10-install/bin/wine \
  reg query 'HKLM\Software\Microsoft\OfficeSoftwareProtectionPlatform' /s
```

Probe log:

```text
/home/mars-user/office-open-repro/logs-latest-authprobe/sppc-auth-probe-after-ospp-plugin-reg.log
```

Result is unchanged:

```text
ReportEventW ... "0x80070002" / "15.0.169.500"
RpcServerUnregisterIf ... {9435cc56-1d9c-4924-ac7d-b60a2c3520e1}
SLOpen hr=0x00000000 handle=00356d18
SLSetAuthenticationData hr=0xc0020012
```

Conclusion: the missing state is not merely the OSPP plugin registry skeleton.
Next candidates are the large binary values under
`OfficeSoftwareProtectionPlatform\data\8fcc4cd6-...`, fuller `osppsvc` service
registration/state, or an OSPPSVC code path that treats some missing file or
registry value as fatal and tears down the RPC interface.

## OSPP Data Blob Test

Checkpoint: 2026-05-30 22:27 UTC

The normal `reg export` path from the known-good prefix only exposed the root
`Path` value, but the raw Wine `system.reg` still contained the large binary
values under:

```text
HKLM\Software\Microsoft\OfficeSoftwareProtectionPlatform\data\8fcc4cd6-36bc-4eb9-bece-10de1b3b8a45
```

Extracted the three values from the known-good raw registry and added them to
the disposable latest authprobe prefix with `reg add /t REG_BINARY`. Verified
the prefix can query values `0`, `1`, and `2`.

Probe log:

```text
/home/mars-user/office-open-repro/logs-latest-authprobe/sppc-auth-probe-after-ospp-data-blobs.log
```

Relevant result:

```text
ReportEventW ... "0x80070002" / "15.0.169.500"
RpcServerUnregisterIf ... {9435cc56-1d9c-4924-ac7d-b60a2c3520e1}
SLOpen hr=0x00000000 handle=00356d18
SLSetAuthenticationData hr=0xc0020012
```

Conclusion: copied known-good OSPP data blobs plus the plugin registry skeleton
are not enough to keep native OSPPSVC alive. The remaining lead is a service
runtime/state mismatch around the native stack at `OSPPSVC.EXE+0xa739f`, or a
Wine builtin `sppc` implementation that avoids relying on the native OSPP
service teardown path.

## OSPP Registry View Correction

Checkpoint: 2026-05-30 22:44 UTC

The previous registry/data tests were incomplete: using the 32-bit `wine reg`
placed the OSPP keys under the redirected `Wow6432Node` registry view, while
64-bit `OSPPSVC.EXE` opens the native key:

```text
HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform
```

After re-adding the root values, plugin registrations, and known-good
`data\8fcc4cd6-...\{0,1,2}` binary blobs with `wine64 reg`, the raw
`system.reg` contains both views, including:

```text
[Software\\Microsoft\\OfficeSoftwareProtectionPlatform\\data\\8fcc4cd6-36bc-4eb9-bece-10de1b3b8a45]
"0"=hex:...
"1"=hex:...
"2"=hex:...
```

Probe log:

```text
/home/mars-user/office-open-repro/logs-latest-authprobe/sppc-auth-probe-after-ospp-64bit-reg.log
```

This clears the previous native OSPP teardown:

```text
SLOpen hr=0x00000000 handle=00356d10
SLSetAuthenticationData hr=0x00000000
SLGetAuthenticationResult hr=0xc004f07a size=0 data=00000000
```

The native HRESULT is `SL_E_AUTHN_CANT_VERIFY`. This is useful because it proves
the earlier `0xc0020012` was caused by OSPPSVC failing to initialize against the
native registry view, not by the auth challenge itself.

## Builtin Auth Result Parity Test

Checkpoint: 2026-05-30 22:44 UTC

Changed Wine builtin `sppc.SLGetAuthenticationResult` so that after
`SLSetAuthenticationData` it mirrors the native OSPP result:

```text
SLGetAuthenticationResult hr=0xc004f07a size=0 data=00000000
```

Probe log:

```text
/home/mars-user/office-open-repro/logs-latest-authprobe/sppc-auth-probe-builtin-cant-verify.log
```

Then launched latest Excel in the disposable authprobe prefix with
`sppc=builtin`:

```text
/home/mars-user/office-open-repro/logs-latest-authprobe/excel-launch-builtin-cant-verify.log
```

Excel still emits repair `702061`:

```text
SLSetAuthenticationData hr=0x00000000
SLGetAuthenticationResult returning native OSPP-compatible authentication verification failure.
ReportEventW event string[1]: "We're sorry, but Excel has run into an error..."
ReportEventW event string[2]: "702061"
```

Conclusion: matching the native auth-result HRESULT is not sufficient. The
native OSPP path must also be supplying materially different policy,
application, or service behavior before Excel decides whether to repair. The
next comparison should focus on policy/application data returned by native OSPP
around the sequence:

```text
SLConsumeRight
SLGetPolicyInformation("*")
SLGetApplicationPolicy("*")
SLGetPolicyInformation("office-C845E028-E091-442E-8202-21F596C559A0")
SLGetAuthenticationResult
SLGetPolicyInformation("office-ParentCode")
SLGetAuthenticationResult
SLGetLicensingStatusInformation
```
