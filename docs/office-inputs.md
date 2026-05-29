# Office Inputs

These notes identify the local Office inputs used during the successful run.
The actual Microsoft binaries and payload caches are not committed here.

## Local Inputs

- Original bootstrapper:
  `/home/mars-user/OfficeSetup.exe`
  - SHA256: `1dd6491f068d450cd686b31e4574da540ad8948bdf1cebbc7feba215fe2c7d2c`
- Archived Office Deployment Tool:
  `/home/mars-user/office-odt/old-officedeploymenttool_12624-20320.exe`
  - SHA256: `ae1cfca801d21559032ecc5f44912b17735d85a8a568258e1a717a14c7738973`
- Extracted archived ODT setup:
  `/home/mars-user/office-odt/old-12624/setup.exe`
  - SHA256: `0e6334e743a0c9d2280d37518026e21a63f937d0506cf5fca6592068e5266699`
- Working install XML:
  `/home/mars-user/office-odt/install-office32-2002-excelonly.xml`
  - SHA256: `4fc8f7a34dc50ddd9d3e729dc394b4453a6450ef2be45cecaf76268a9811fdf4`
- Office payload cache:
  `/home/mars-user/office-cache32-2002`
  - Version: `16.0.12527.21416`
  - Channel: `SemiAnnual`
  - Edition: 32-bit
  - Product: `O365HomePremRetail`
  - App set: Excel only, most other Office apps excluded

## Working XML

```xml
<Configuration>
  <Add OfficeClientEdition="32" Channel="SemiAnnual" Version="16.0.12527.21416" SourcePath="Z:\home\mars-user\office-cache32-2002">
    <Product ID="O365HomePremRetail">
      <Language ID="en-us" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="Outlook" />
      <ExcludeApp ID="PowerPoint" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
      <ExcludeApp ID="Word" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="0" />
  <Updates Enabled="FALSE" />
</Configuration>
```
