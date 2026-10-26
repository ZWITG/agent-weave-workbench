; Inno Setup script for the Relivable Windows installer.
; Built in CI: ISCC /DAppVersion=<version> /DSourceDir=<release folder> relivable.iss

#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
AppId={{6E1C7B4A-3F7D-4C55-9A2E-9B8F1D3C2A11}
AppName=Relivable
AppVersion={#AppVersion}
AppPublisher=ZWITG
DefaultDirName={localappdata}\Programs\Relivable
DefaultGroupName=Relivable
PrivilegesRequired=lowest
OutputBaseFilename=RelivableSetup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\Relivable.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Relivable"; Filename: "{app}\Relivable.exe"
Name: "{autodesktop}\Relivable"; Filename: "{app}\Relivable.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Relivable.exe"; Description: "Play Relivable now"; Flags: nowait postinstall skipifsilent
