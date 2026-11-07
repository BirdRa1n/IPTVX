; IPTVX — Windows installer (Inno Setup 6).
;
; Built by packaging/windows/package.ps1:
;   iscc /DAppVersion=0.2.0 /DSourceDir=<deployed dir> /DRepoDir=<repo>
;        /DOutputDir=<dir> /DOutputName=IPTVX-0.2.0-windows-x64-setup iptvx.iss
;
; Per-user install (no administrator rights, no UAC prompt), so the in-app
; updater can run it silently: /SILENT /SUPPRESSMSGBOXES /CLOSEAPPLICATIONS.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{8C8B6E2A-6C4E-4B7E-9C1D-2F1F0B5A9E31}
AppName=IPTVX
AppVersion={#AppVersion}
AppVerName=IPTVX {#AppVersion}
AppPublisher=IPTVX
AppPublisherURL=https://github.com/BirdRa1n/IPTVX
AppSupportURL=https://github.com/BirdRa1n/IPTVX/issues
AppUpdatesURL=https://github.com/BirdRa1n/IPTVX/releases
DefaultDirName={localappdata}\Programs\IPTVX
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename={#OutputName}
SetupIconFile={#RepoDir}\resources\icons\iptvx.ico
UninstallDisplayIcon={app}\IPTVX.exe
UninstallDisplayName=IPTVX
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
VersionInfoVersion={#AppVersion}
VersionInfoProductName=IPTVX
VersionInfoDescription=IPTVX installer

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Remove the previous deployment so no stale Qt plugin or QML file survives
; an update (user data lives in %APPDATA%, not here).
Type: filesandordirs; Name: "{app}\*"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\IPTVX"; Filename: "{app}\IPTVX.exe"
Name: "{autodesktop}\IPTVX"; Filename: "{app}\IPTVX.exe"; Tasks: desktopicon

[Run]
; Also runs in /SILENT mode, which relaunches IPTVX after a self-update.
Filename: "{app}\IPTVX.exe"; Description: "{cm:LaunchProgram,IPTVX}"; Flags: nowait postinstall
