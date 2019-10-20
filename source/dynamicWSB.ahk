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
  __New(path, isReadOnly) {
    ; Trim any whitespace
    isReadOnly := StrReplace(isReadOnly, " " , "")
    this.path := path
    If (isReadOnly = "") {
      this.isReadOnly := "true"
    } Else {
      this.isReadOnly := isReadOnly
    }
  }
}

mappedFolder(pathItem, isRelative) {
  global mappedFoldersArr
  ; Cleanup brackets
  pathItem := RegExReplace(pathItem, "[\[\]]", "")
  pathValueRaw := StrSplit(pathItem, "|")
  If (isRelative = true) {
    SetWorkingDir % A_ScriptDir "/" pathValueRaw[1]
    pathValueRaw[1] := A_WorkingDir
    SetWorkingDir, %A_ScriptDir%
  }
  mappedFolderItem := new MappedFolder(pathValueRaw[1], pathValueRaw[2])
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
  buffer := buffer "      <HostFolder>" folderObj.path "</HostFolder>`n"
  buffer := buffer "      <ReadOnly>" folderObj.isReadOnly "</ReadOnly>`n"
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
config := config "  <LogonCommand>`n"
config := config "  " configSetting("Command", logonCommand)
config := config "  </LogonCommand>`n"
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