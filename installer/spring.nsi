; Script generated by the HM NIS Edit Script Wizard.

; Compiler-defines to generate different types of installers
;   SP_UPDATE - Only include changed files and no maps

!addPluginDir "nsis_plugins"

; Use the 7zip-like compressor
SetCompressor lzma

!include "springsettings.nsh"
!include "LogicLib.nsh"
!include "Sections.nsh"
!include "WordFunc.nsh"
!insertmacro VersionCompare

; HM NIS Edit Wizard helper defines
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\SpringClient.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; MUI 1.67 compatible ------
!include "MUI.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "graphics\InstallerIcon.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "graphics\SideBanner.bmp"
;!define MUI_COMPONENTSPAGE_SMALLDESC ;puts description on the bottom, but much shorter.
!define MUI_COMPONENTSPAGE_TEXT_TOP "Some of these components must be downloaded during the install process."



; Welcome page
!insertmacro MUI_PAGE_WELCOME
; Licensepage
!insertmacro MUI_PAGE_LICENSE "gpl.txt"

; Components page
!insertmacro MUI_PAGE_COMPONENTS

; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page

!define BUILDDIR "..\build"

!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\docs\main.html"
!define MUI_FINISHPAGE_RUN "$INSTDIR\springsettings.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Configure ${PRODUCT_NAME} settings now"
!define MUI_FINISHPAGE_TEXT "${PRODUCT_NAME} version ${PRODUCT_VERSION} has been successfully installed or updated from a previous version.  You should configure Spring settings now if this is a fresh installation.  If you did not install spring to C:\Program Files\Spring you will need to point the settings program to the install location."

; Finish page
;!ifndef SP_UPDATE

;!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\docs\main.html"
;!define MUI_FINISHPAGE_TEXT "${PRODUCT_NAME} version ${PRODUCT_VERSION} has been successfully installed on your computer. It is recommended that you configure Spring settings now if this is a fresh installation, otherwise you may encounter problems."

;!define MUI_FINISHPAGE_RUN "$INSTDIR\settings.exe"
;!define MUI_FINISHPAGE_RUN_TEXT "Configure ${PRODUCT_NAME} settings now"

;!else

;!define MUI_FINISHPAGE_TEXT "${PRODUCT_NAME} version ${PRODUCT_VERSION} has been successfully updated from a previous version."

;!endif


!define MUI_FINISHPAGE_LINK "The ${PRODUCT_NAME} website"
!define MUI_FINISHPAGE_LINK_LOCATION ${PRODUCT_WEB_SITE}
!define MUI_FINISHPAGE_NOREBOOTSUPPORT

!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; MUI end ------

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"

;!ifdef SP_UPDATE
;!define SP_OUTSUFFIX1 "_update"
;!else
!define SP_OUTSUFFIX1 ""
;!endif

OutFile "${SP_BASENAME}${SP_OUTSUFFIX1}.exe"
InstallDir "$PROGRAMFILES\Spring"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
;ShowInstDetails show ;fix graphical glitch
;ShowUnInstDetails show ;fix graphical glitch

!include "include\fileassoc.nsh"
!include "include\checkrunning.nsh"


Function .onInit
!ifndef TEST_BUILD
  ; check if we need to exit some processes which may be using unitsync
  call CheckTASClientRunning
  call CheckSpringDownloaderRunning
  call CheckCADownloaderRunning
  call CheckSpringLobbyRunning
  call CheckSpringSettingsRunning
!endif

  ;Push $0 ; Create variable $0

  ; The core cannot be deselected
  ;SectionGetFlags 0 $0 ; Get the current selection of the first component and store in variable $0
  ;IntOp $0 $0 | 16 ; Change the selection flag in variable $0 to read only (16)
  ;SectionSetFlags 0 $0 ; Set the selection flag of the first component to the contents of variable $0

  ;Pop $0 ; Delete variable $0
  ${IfNot} ${FileExists} "$INSTDIR\spring.exe"
    !insertmacro SetSectionFlag 0 16 ; make the core section read only
  ${EndIf}
  !insertmacro UnselectSection 3 ; unselect TASClient section (3) by default
  ${If} ${FileExists} "$INSTDIR\spring.exe"
    !insertmacro UnselectSection 6 ; unselect default section (6) by default
  ${EndIf}
  ;!insertmacro SetSectionFlag 10 32 ; expand (32) mods section (10)
FunctionEnd


Function GetDotNETVersion
  Push $0 ; Create variable 0 (version number).
  Push $1 ; Create variable 1 (error).

  ; Request the version number from the Microsoft .NET Runtime Execution Engine DLL
  System::Call "mscoree::GetCORVersion(w .r0, i ${NSIS_MAX_STRLEN}, *i) i .r1 ?u"

 ; If error, set "not found" as the top element of the stack. Otherwise, set the version number.
  StrCmp $1 "error" 0 +2 ; If variable 1 is equal to "error", continue, otherwise skip the next couple of lines.
  StrCpy $0 "not found"
  Pop $1 ; Remove variable 1 (error).
  Exch $0 ; Place variable  0 (version number) on top of the stack.
FunctionEnd

Function NoDotNet
  MessageBox MB_YESNO \
  "The .NET runtime library is not installed. v2.0 or newer is required for the Complete Annihilation automatic updates. Do you wish to download and install it?" \
  IDYES true IDNO false
true:
    inetc::get "http://installer.clan-sy.com/dotnetfx.exe"   "$INSTDIR\dotnetfx.exe"
    ExecWait "$INSTDIR\dotnetfx.exe"
    Delete   "$INSTDIR\dotnetfx.exe"
  Goto next
false:
next:
FunctionEnd

Function OldDotNet
  MessageBox MB_YESNO \
  ".NET runtime library v2.0 or newer is required for Complete Annihilation automatic updates. You have $0. Do you wish to download and install it?" \
    IDYES true IDNO false
true:
    inetc::get \
             "http://installer.clan-sy.com/dotnetfx.exe"   "$INSTDIR\dotnetfx.exe"
    ExecWait "$INSTDIR\dotnetfx.exe"
    Delete   "$INSTDIR\dotnetfx.exe"
  Goto next
false:
next:
FunctionEnd


Section "Main application (req)" SEC_MAIN
!ifdef SP_UPDATE
!ifndef TEST_BUILD
  Call CheckVersion
!endif
!endif
  !define INSTALL
  !include "sections\main.nsh"
  !include "sections\luaui.nsh"
  !undef INSTALL
SectionEnd


SectionGroup "Multiplayer battlerooms"
  Section "SpringLobby" SEC_SPRINGLOBBY
  !define INSTALL
  !include "sections\springlobby.nsh"
  !undef INSTALL
  SectionEnd
  
  Section "TASClient (only Multiplayer)" SEC_TASCLIENT
  !define INSTALL
  !include "sections\tasclient.nsh"
  !undef INSTALL
  SectionEnd
SectionGroupEnd


Section "Start menu shortcuts" SEC_START
  !define INSTALL
  !include "sections\shortcuts.nsh"
  !undef INSTALL
SectionEnd

Section "Desktop shortcut" SEC_DESKTOP
  ${If} ${SectionIsSelected} ${SEC_TASCLIENT}
  SetOutPath "$INSTDIR"
    !ifdef TEST_BUILD
      CreateShortCut "$DESKTOP\${PRODUCT_NAME} battleroom.lnk" "$INSTDIR\TASClient.exe" "-server taspringmaster.servegame.com:8300"
    !else
      CreateShortCut "$DESKTOP\${PRODUCT_NAME} battleroom.lnk" "$INSTDIR\TASClient.exe"
    !endif
  ${EndIf}
SectionEnd

Section "Easy content installation" SEC_ARCHIVEMOVER
  !define INSTALL
  !include "sections\archivemover.nsh"
  !undef INSTALL
SectionEnd

SectionGroup "Skirmish AI plugins (Bots)"
	Section "AAI" SEC_AAI
	!define INSTALL
	!include "sections\aai.nsh"
	!undef INSTALL
	SectionEnd

	Section "KAIK" SEC_KAIK
	!define INSTALL
	!include "sections\kaik.nsh"
	!undef INSTALL
	SectionEnd

	Section "RAI" SEC_RAI
	!define INSTALL
	!include "sections\rai.nsh"
	!undef INSTALL
	SectionEnd
SectionGroupEnd

!include "sections\sectiondesc.nsh"

Section -Documentation
  !define INSTALL
  !include "sections\docs.nsh"
  !undef INSTALL
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\springclient.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\spring.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

Function un.onUninstSuccess
  IfSilent +3
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  IfSilent +3
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall

  !include "sections\main.nsh"

  !include "sections\docs.nsh"
  !include "sections\shortcuts.nsh"
  !include "sections\archivemover.nsh"
  !include "sections\aai.nsh"
  !include "sections\kaik.nsh"
  !include "sections\rai.nsh"
  !include "sections\tasclient.nsh"
  !include "sections\springlobby.nsh"
  !include "sections\luaui.nsh"

  Delete "$DESKTOP\${PRODUCT_NAME} battleroom.lnk"

  ; All done
  RMDir "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd
