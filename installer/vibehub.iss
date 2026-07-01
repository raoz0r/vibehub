#ifndef AppVersion
#define AppVersion "1.0.0"
#endif

#ifndef SourceDir
#define SourceDir "..\app\build\windows\x64\runner\Release"
#endif

#ifndef OutputDir
#define OutputDir "..\app"
#endif

[Setup]
AppId={{0C97A6F4-5C7E-4637-AB44-0C1B9C835204}
AppName=VibeHub
AppVersion={#AppVersion}
AppPublisher=VibeHub
DefaultDirName={localappdata}\Programs\VibeHub
DefaultGroupName=VibeHub
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=VibeHubSetup-windows-x64-v{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\vibehub.exe

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
Name: "{localappdata}\vibehub\Data"; Flags: uninsneveruninstall
Name: "{userappdata}\vibehub\Config"; Flags: uninsneveruninstall
Name: "{localappdata}\vibehub\Cache"; Flags: uninsneveruninstall
Name: "{localappdata}\vibehub\Log"; Flags: uninsneveruninstall

[Icons]
Name: "{group}\VibeHub"; Filename: "{app}\vibehub.exe"
Name: "{userdesktop}\VibeHub"; Filename: "{app}\vibehub.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\vibehub.exe"; Description: "Launch VibeHub"; Flags: nowait postinstall skipifsilent
