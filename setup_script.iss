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
; 1. ملفات نسخة الـ 64-bit (الناتجة من بناء جيت هوب)
Source: "C:\AqaratApp_x64\*"; DestDir: "{app}"; Check: Is64BitInstallMode; Flags: ignoreversion recursesubdirs createallsubdirs

; 2. ملفات نسخة الـ 32-bit (الناتجة من البناء المحلي)
Source: "C:\AqaratApp_x86\*"; DestDir: "{app}"; Check: not Is64BitInstallMode; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; اختصار الـ 64-bit على سطح المكتب وقائمة Start
Name: "{autodesktop}\منظومة العقارات"; Filename: "{app}\aqarat_app.exe"; Check: Is64BitInstallMode; Tasks: desktopicon
Name: "{group}\منظومة العقارات"; Filename: "{app}\aqarat_app.exe"; Check: Is64BitInstallMode

; اختصار الـ 32-bit على سطح المكتب وقائمة Start
Name: "{autodesktop}\منظومة العقارات"; Filename: "{app}\aqarat_app.exe"; Check: not Is64BitInstallMode; Tasks: desktopicon
Name: "{group}\منظومة العقارات"; Filename: "{app}\aqarat_app.exe"; Check: not Is64BitInstallMode

[Run]
Filename: "{app}\aqarat_app.exe"; Description: "{cm:LaunchProgram,منظومة العقارات}"; Flags: postinstall nowait skipifsilent