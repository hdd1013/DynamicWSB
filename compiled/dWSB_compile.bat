REM Compiler script for DynamicWSB. AHK must be installed on your computer. See https://www.autohotkey.com/docs/Scripts.htm#ahk2exe for more details

@cd %~dp0
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "..\source\dynamicWSB.ahk" /out ".\dynamicWSB.exe" /compress 1
xcopy /s /e /d "..\source\dynamicWSBSettings\" ".\dynamicWSBSettings\"

@echo Compile Completed

pause