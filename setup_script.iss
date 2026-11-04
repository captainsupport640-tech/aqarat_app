[Setup]
AppId={{A3C8892D-1234-4567-89AB-CDEF12345678}
AppName=منظومة الكابتن لإدارة العقارات
AppVersion=1.0.0
AppPublisher=Captain Abdo
DefaultDirName={autopf}\AqaratApp
DefaultGroupName=منظومة الكابتن لإدارة العقارات
OutputDir=output
OutputBaseFilename=العقارات-Setup
SetupIconFile=C:\Projects\aqarat_app\windows\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

; دعم التثبيت على أنظمة 32-bit و 64-bit
ArchitecturesAllowed=x86 x64
ArchitecturesInstallIn64BitMode=x64

; يتعرف أوتوماتيكياً على لغة ويندوز العميل ويسمح له بتغييرها
ShowLanguageDialog=auto

[Languages]
; اللغة العربية هي الافتراضية إذا لم يتعرف على لغة الجهاز
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; 1. ملفات نسخة الـ 64-bit (تتثبت أوتوماتيكياً لو الويندوز 64)
Source: "C:\AqaratApp_x64\*"; DestDir: "{app}"; Check: Is64BitInstallMode; Flags: ignoreversion recursesubdirs createallsubdirs

; 2. ملفات نسخة الـ 32-bit (تتثبت أوتوماتيكياً لو الويندوز 32)
Source: "C:\AqaratApp_x86\*"; DestDir: "{app}"; Check: not Is64BitInstallMode; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; اختصار موحد بأيقونة واحدة على سطح المكتب وقائمة Start بغض النظر عن النواة
Name: "{autodesktop}\منظومة العقارات"; Filename: "{app}\aqarat.exe"; Tasks: desktopicon
Name: "{group}\منظومة العقارات"; Filename: "{app}\aqarat.exe"

[Run]
Filename: "{app}\aqarat.exe"; Description: "{cm:LaunchProgram,منظومة العقارات}"; Flags: postinstall nowait skipifsilent