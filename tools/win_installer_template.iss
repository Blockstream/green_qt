#define MyAppName "Green"
#define MyAppVersion "VERSION_STRING"
#define MyAppPublisher "Blockstream"
#define MyAppURL "https://blockstream.com/green/"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{3AD17C10-A864-47AB-895F-FA44CA654295}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppPublisher}\{#MyAppName}
UninstallFilesDir={pf}\{#MyAppPublisher}\{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppName}.exe
DefaultGroupName={#MyAppPublisher}
OutputDir=.
OutputBaseFilename=GreenSetup
Compression=lzma
SolidCompression=yes
ChangesEnvironment=true
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 0,6.1

[Files]
Source: "Green.exe"; DestDir: "{app}"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppName}.exe"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppName}.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppName}.exe"; Tasks: quicklaunchicon

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C ""taskkill /im {#MyAppName}.exe /f"
