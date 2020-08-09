;@Ahk2Exe-SetVersion     1.20.08.01
;@Ahk2Exe-SetName        DynamicWSB
;@Ahk2Exe-SetProductName DynamicWSB
;@Ahk2Exe-SetCopyright   hdd1013 (https://github.com/hdd1013/dynamicWSB)
;@Ahk2Exe-SetDescription Windows Sandbox Execution Proxy with relative path support for mapped folders.

SetWorkingDir, %A_ScriptDir%
scriptDir = %A_ScriptDir%
scriptName := RegExReplace(A_ScriptName, "i)(\.ahk|\.exe)", "")
settingsDir := A_ScriptDir "\" scriptName "Settings"
settingsIni := settingsDir "\settings.ini"

; Read INI file
; Function resolveSetting
resolveSetting(iniSection, iniKey, ifEmpty, ifErr) {
  global settingsIni
  IniRead, settingVar, %settingsIni%, %iniSection%, %iniKey%
  If (settingVar="") {
    settingVar := ifEmpty
  }
  If (settingVar="ERROR") {
    settingVar := ifErr
  }
  return settingVar
}

; VGpu
vgpu := resolveSetting("SystemSettings", "VGpu", "Default", "ERROR")
; Networking
networking := resolveSetting("SystemSettings", "Networking", "Default", "ERROR")

; Mapped Folders
IniRead, relativePaths, %settingsIni%, MappedFolders, RelativePaths
relativePathsArr := StrSplit(relativePaths, "],")
IniRead, absolutePaths, %settingsIni%, MappedFolders, AbsolutePaths
absolutePathsArr := StrSplit(absolutePaths, "],")

mappedFoldersArr := array()
Class MappedFolder {
  __New(path, isReadOnly, mountTarget) {
    ; Trim any whitespace
    isReadOnly := StrReplace(isReadOnly, " " , "")
    mountTarget := StrReplace(mountTarget, " " , "")
    this.path := path
    If (isReadOnly = "") {
      this.isReadOnly := "true"
    } Else {
      this.isReadOnly := isReadOnly
    }
    If(mountTarget = "") {
      this.mountTarget := ""
    } Else {
      this.mountTarget := mountTarget
    }
  }
}

mappedFolder(pathItem, isRelative) {
  global mappedFoldersArr
  ; Cleanup brackets
  pathItem := RegExReplace(pathItem, "[\[\]]", "")
  pathValueRaw := StrSplit(pathItem, "|")
  
  folderPath := pathValueRaw[1]
  folderReadOnly := pathValueRaw[2]
  folderTarget := pathValueRaw[3]

  If (isRelative = true) {
    SetWorkingDir % A_ScriptDir "/" folderPath
    folderPath := A_WorkingDir
    SetWorkingDir, %A_ScriptDir%
  }
  mappedFolderItem := new MappedFolder(folderPath, folderReadOnly, folderTarget)
  mappedFoldersArr.push(mappedFolderItem)
}

Loop % relativePathsArr.MaxIndex() {
  mappedFolder(relativePathsArr[A_Index], true)
}
Loop % absolutePathsArr.MaxIndex() {
  mappedFolder(absolutePathsArr[A_Index], false)
}

; LogonCommand
logonCommand := resolveSetting("LogonCommand", "Command", "ERROR", "ERROR")

; Build Output
configSetting(varName, varValue) {
  If (varValue="ERROR") {
    return
  } Else {
    buffer := "  <" varName ">" varValue "</" varName ">`n"
    return buffer
  }
}
buildMappedFolder(folderObj) {
  buffer := "    <MappedFolder>`n"
  If (folderObj.path != "") {
    buffer := buffer "      <HostFolder>" folderObj.path "</HostFolder>`n"
  }
  If (folderObj.mountTarget != "") {
    buffer := buffer "      <SandboxFolder>" folderObj.mountTarget "</SandboxFolder>`n"
  }
  If (folderObj.isReadOnly != "") {
    buffer := buffer "      <ReadOnly>" folderObj.isReadOnly "</ReadOnly>`n"
  }
  buffer := buffer "    </MappedFolder>`n"
  return buffer
}

config := "<Configuration>`n"
config := config configSetting("VGpu", vgpu)
config := config configSetting("Networking", networking)
config := config "  <MappedFolders>`n"

; Mapped Folders
Loop % mappedFoldersArr.MaxIndex() {
  config := config buildMappedFolder(mappedFoldersArr[A_Index])
}

config := config "  </MappedFolders>`n"

If (configSetting("Command", logonCommand) = "") {

} Else {
  config := config "  <LogonCommand>`n"
  config := config "  " configSetting("Command", logonCommand) "`n"
  config := config "  </LogonCommand>`n"
}
config := config "</Configuration>"

; Output file
filePattern := settingsDir "\" scriptName ".wsb"
If ( FileExist(filePattern) ) {
  try {
    FileDelete, %filePattern%
  } catch e {
    MsgBox, File Deletion Failed!`nError Code: %A_LastError%`nTry checking your antivirus software.
  }
}
FileAppend, %config%, %filePattern%
SetWorkingDir, %scriptDir%

runPath := "C:\WINDOWS\system32\WindowsSandbox.exe " filePattern
Run %runPath%

Return