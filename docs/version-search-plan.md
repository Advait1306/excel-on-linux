# Office Version Search Plan

The known-good baseline is Office `16.0.12527.21416` from the archived ODT 2002 payload.
The current ODT Current Channel test installed/staged `16.0.20026.20112` but failed during license integration and then crashed on direct Excel launch.

## Source References

- Microsoft 365 Apps update history:
  `https://learn.microsoft.com/en-us/officeupdates/update-history-microsoft365-apps-by-date`
- Office Deployment Tool configuration options:
  `https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/office-deployment-tool-configuration-options`

Microsoft's update history currently lists these supported builds:

- Current Channel 2605: `16.0.20026.20112`
- Monthly Enterprise 2604: `16.0.19929.20172`
- Semi-Annual Enterprise 2508: `16.0.19127.20648`

ODT supports pinning a build with the `Version` attribute and recommends specifying `Channel` with it. ODT channel values include `Current`, `MonthlyEnterprise`, and `SemiAnnual`.

## Candidate Order

Start with Semi-Annual Enterprise builds before trying more Current/Monthly builds. They are newer than the working 2002 payload but should have fewer newest-channel dependencies than Current 2605.

1. `config/office-step-semiannual-2308-excelonly.xml`
   - Channel: `SemiAnnual`
   - Version: `16.0.16731.21114`
   - Reason: much newer than 2002 but far behind the modern WinRT/auth-heavy 2605 payload.
2. `config/office-step-semiannual-2408-excelonly.xml`
   - Channel: `SemiAnnual`
   - Version: `16.0.17928.20776`
   - Reason: supported Semi-Annual build and a good mid-point.
3. `config/office-step-semiannual-2508-excelonly.xml`
   - Channel: `SemiAnnual`
   - Version: `16.0.19127.20648`
   - Reason: newest supported Semi-Annual Enterprise build currently listed.

If one of these installs and launches Excel, bisect upward toward Monthly Enterprise/Current builds. If all fail with the same license-integration or WinRT/auth launch errors, the next branch is targeted Wine stubbing/implementation for the missing modern APIs.

## Run Pattern

Use a fresh disposable prefix for each candidate:

```bash
PREFIX=/home/mars-user/.local/share/office-proton/compatdata/office-step-semiannual-2308/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-office-step-semiannual-2308 \
OFFICE_XML=/home/mars-user/excel-on-linux/config/office-step-semiannual-2308-excelonly.xml \
/home/mars-user/excel-on-linux/scripts/office-latest-experiment.sh init-prefix

PREFIX=/home/mars-user/.local/share/office-proton/compatdata/office-step-semiannual-2308/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-office-step-semiannual-2308 \
OFFICE_XML=/home/mars-user/excel-on-linux/config/office-step-semiannual-2308-excelonly.xml \
/home/mars-user/excel-on-linux/scripts/office-latest-experiment.sh apply-overrides

PREFIX=/home/mars-user/.local/share/office-proton/compatdata/office-step-semiannual-2308/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-office-step-semiannual-2308 \
OFFICE_XML=/home/mars-user/excel-on-linux/config/office-step-semiannual-2308-excelonly.xml \
/home/mars-user/excel-on-linux/scripts/office-latest-experiment.sh install-native-msxml6

PREFIX=/home/mars-user/.local/share/office-proton/compatdata/office-step-semiannual-2308/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-office-step-semiannual-2308 \
OFFICE_XML=/home/mars-user/excel-on-linux/config/office-step-semiannual-2308-excelonly.xml \
/home/mars-user/excel-on-linux/scripts/office-latest-experiment.sh install-winscard-stub

PREFIX=/home/mars-user/.local/share/office-proton/compatdata/office-step-semiannual-2308/pfx \
LOG_DIR=/home/mars-user/office-open-repro/logs-office-step-semiannual-2308 \
OFFICE_XML=/home/mars-user/excel-on-linux/config/office-step-semiannual-2308-excelonly.xml \
/home/mars-user/excel-on-linux/scripts/office-latest-experiment.sh run-latest-odt
```
