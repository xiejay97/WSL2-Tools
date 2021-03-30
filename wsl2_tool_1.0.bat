::  Reference to Microsoft-Activation-Scripts [ https://github.com/massgravel/Microsoft-Activation-Scripts ].

@setlocal DisableDelayedExpansion
@echo off

::========================================================================================================================================

cls
chcp 65001>nul 2>nul
title WSL2 Tools 1.0
set _elev=
if /i "%~1"=="-el" set _elev=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
set "_null=1>nul 2>nul"
set "_psc=powershell"
set "EchoRed=%_psc% write-host -back Black -fore Red"
set "EchoGreen=%_psc% write-host -back Black -fore Green"
set "ErrLine=echo: & %EchoRed% ==== ERROR ==== &echo:"

::========================================================================================================================================

for %%i in (powershell.exe) do if "%%~$path:i"=="" (
echo: &echo ==== ERROR ==== &echo:
echo Powershell is not installed in the system.
echo Aborting...
goto ErrExit
)

::========================================================================================================================================

if %winbuild% LSS 18362 (
%ErrLine%
echo Unsupported OS version Detected.
echo Project is supported only for Windows 10: Version 1903 or higher, with Build 18362 or higher.
goto ErrExit
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop
::  Thanks to @hearywarlot [ https://forums.mydigitallife.net/threads/.74332/ ] for the VBS method.
::  Thanks to @abbodi1406 for the powershell method and solving special characters issue in file path name.

set "batf_=%~f0"
set "batp_=%batf_:'=''%"

%_null% reg query HKU\S-1-5-19 && (
goto :_Passed
) || (
if defined _elev goto :_E_Admin
)

set "_vbsf=%temp%\admin.vbs"
set _PSarg="""%~f0""" -el

setlocal EnableDelayedExpansion
(
echo Set strArg=WScript.Arguments.Named
echo Set strRdlproc = CreateObject^("WScript.Shell"^).Exec^("rundll32 kernel32,Sleep"^)
echo With GetObject^("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" ^& strRdlproc.ProcessId ^& "'"^)
echo With GetObject^("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" ^& .ParentProcessId ^& "'"^)
echo If InStr ^(.CommandLine, WScript.ScriptName^) ^<^> 0 Then
echo strLine = Mid^(.CommandLine, InStr^(.CommandLine , "/File:"^) + Len^(strArg^("File"^)^) + 8^)
echo End If
echo End With
echo .Terminate
echo End With
echo CreateObject^("Shell.Application"^).ShellExecute "cmd.exe", "/c " ^& chr^(34^) ^& chr^(34^) ^& strArg^("File"^) ^& chr^(34^) ^& strLine ^& chr^(34^), "", "runas", 1
)>"!_vbsf!"

(%_null% cscript //NoLogo "!_vbsf!" /File:"!batf_!" -el) && (
del /f /q "!_vbsf!"
exit /b
) || (
del /f /q "!_vbsf!"
%_null% %_psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && (
exit /b
) || (
goto :_E_Admin
)
)
exit /b

:_E_Admin
%ErrLine%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'.
goto ErrExit

:_Passed

::========================================================================================================================================

setlocal EnableDelayedExpansion

:MainMenu

cls
title WSL2 Tools 1.0
mode con cols=98 lines=30

echo:
echo:
echo                   _______________________________________________________________
echo                  ^|                                                               ^| 
echo                  ^|                                                               ^|
echo                  ^|      [1] Read Me                                              ^|
echo                  ^|      ___________________________________________________      ^|
echo                  ^|                                                               ^|
echo                  ^|      [2] Port Proxy                                           ^|
echo                  ^|                                                               ^|
echo                  ^|      [3] Net Proxy                                            ^|
echo                  ^|                                                               ^|
echo                  ^|      [4] IP Setting                                           ^|
echo                  ^|      ___________________________________________________      ^|
echo                  ^|                                                               ^|
echo                  ^|      [5] Exit                                                 ^|
echo                  ^|                                                               ^|
echo                  ^|_______________________________________________________________^|
echo:          
choice /C:12345 /N /M ">                   Enter Your Choice in the Keyboard [1,2,3,4,5] : "

if errorlevel  5 goto:Exit
if errorlevel  4 goto:IPSetting 
if errorlevel  3 goto:NetProxy
if errorlevel  2 goto:PortProxy
if errorlevel  1 goto:Readme

::========================================================================================================================================

:ReadMe

start https://github.com/Xie-Jay/WSL2-Tools  &goto MainMenu

::========================================================================================================================================

:PortProxy

cls
title Port Proxy
mode con cols=98 lines=30

echo:
echo:
echo                      _________________________________________________________   
echo                     ^|                                                         ^|
echo                     ^|                                                         ^|
echo                     ^|     [1] Add Port Proxy                                  ^|
echo                     ^|                                                         ^|
echo                     ^|     [2] Reset Port Proxy                                ^|
echo                     ^|                                                         ^|
echo                     ^|     [3] Show Port Proxy                                 ^|
echo                     ^|                                                         ^|
echo                     ^|     _______________________________________________     ^|
echo                     ^|                                                         ^|
echo                     ^|     [4] Go to Main Menu                                 ^|
echo                     ^|                                                         ^|
echo                     ^|_________________________________________________________^|
echo:                                                                               
choice /C:1234 /N /M ">                     Enter Your Choice [1,2,3,4] : "

if errorlevel 4 goto:MainMenu
if errorlevel 3 goto:ShowPortProxy
if errorlevel 2 goto:ResetPortProxy
if errorlevel 1 goto:AddPortProxy

:AddPortProxy
for /f %%j in ('bash.exe -c "hostname -I | awk '{print $1}'"') do (
    set wslip=%%j
)
echo:
set input=
set /p input=">                     Enter Ports(separated by spaces):"
set s=%input%
:loop
for /f "tokens=1*" %%a in ("%s%") do (
    netsh interface portproxy add v4tov4 listenport=%%a listenaddress=0.0.0.0 connectport=%%a connectaddress=%wslip% >nul
    set s=%%b
)
if defined s goto :loop
echo:
netsh interface portproxy show v4tov4
echo:
echo                       Press any key to continue...
pause >nul
goto PortProxy

:ResetPortProxy
netsh interface portproxy reset 
echo:
echo                       Success!
echo:
echo                       Press any key to continue...
pause >nul
goto PortProxy

:ShowPortProxy
echo:
netsh interface portproxy show v4tov4
echo:
echo                       Press any key to continue...
pause >nul
goto PortProxy

::========================================================================================================================================

:NetProxy

cls
title Net Proxy
mode con cols=98 lines=30

echo:
echo:
echo                      _________________________________________________________   
echo                     ^|                                                         ^|
echo                     ^|                                                         ^|
echo                     ^|     [1] Set Proxy Command                               ^|
echo                     ^|                                                         ^|
echo                     ^|     [2] Clear Proxy Command                             ^|
echo                     ^|                                                         ^|
echo                     ^|     [3] Set Always Open Proxy                                 ^|
echo                     ^|                                                         ^|
echo                     ^|     _______________________________________________     ^|
echo                     ^|                                                         ^|
echo                     ^|     [4] Go to Main Menu                                 ^|
echo                     ^|                                                         ^|
echo                     ^|_________________________________________________________^|
echo:                                                                               
choice /C:1234 /N /M ">                     Enter Your Choice [1,2,3,4] : "

if errorlevel 4 goto:MainMenu
if errorlevel 3 goto:SetAlwaysProxy
if errorlevel 2 goto:ClearProxyCommand
if errorlevel 1 goto:SetProxyCommand

:SetProxyCommand
echo:
set input=
set /p input=">                     Enter Http(s) Port:"
set http_port=%input%
echo:
set input=
set /p input=">                     Enter Socks Port:"
set socks_port=%input%
bash.exe -c "sed -i '/export hostip/d;/alias set_proxy/d;/alias clear_proxy/d' ~/.bashrc"
bash.exe -c "sed -i $'$a export hostip=ip route | grep default | awk \'{print $3}\'' ~/.bashrc"
bash.exe -c "sed -i $'$a alias set_proxy=\'export https_proxy=\"http://${hostip}:%http_port%\";export http_proxy=\"http://${hostip}:%http_port%\";export all_proxy=\"socks5://${hostip}:%socks_port%\";\'' ~/.bashrc"
bash.exe -c "sed -i $'$a alias clear_proxy=\'unset https_proxy;unset http_proxy;unset all_proxy;\'' ~/.bashrc"
bash.exe -c "source ~/.bashrc"
echo:
echo                       Success!
echo                       Opne  proxy with command: set_proxy
echo                       Close proxy with command: clear_proxy
echo:
echo                       Press any key to continue...
pause >nul
goto NetProxy

:ClearProxyCommand
bash.exe -c "sed -i '/export hostip/d;/set_proxy/d;/clear_proxy/d' ~/.bashrc"
bash.exe -c "source ~/.bashrc"
echo:
echo                       Success!
echo:
echo                       Press any key to continue...
pause >nul
goto NetProxy

:SetAlwaysProxy
echo:
choice /C:YN /N /M ">                     Always Open Proxy [Y,N] : "
if errorlevel 2 bash.exe -c "sed -i '/^set_proxy$/d' ~/.bashrc"
if errorlevel 1 bash.exe -c "sed -i $'$a set_proxy' ~/.bashrc"
bash.exe -c "source ~/.bashrc"
echo:
echo                       Success!
echo:
echo                       Press any key to continue...
pause >nul
goto NetProxy

::========================================================================================================================================

:IPSetting

cls
title IP Setting
mode con cols=98 lines=30

echo:
echo:
echo                      _________________________________________________________   
echo                     ^|                                                         ^|
echo                     ^|                                                         ^|
echo                     ^|     [1] Add Linux IP                                    ^|
echo                     ^|                                                         ^|
echo                     ^|     [2] Add Windows IP                                  ^|
echo                     ^|                                                         ^|
echo                     ^|     [3] Delete Linux IP                                 ^|
echo                     ^|                                                         ^|
echo                     ^|     [4] Delete Windows IP                               ^|
echo                     ^|                                                         ^|
echo                     ^|     [5] Show IP                                         ^|
echo                     ^|                                                         ^|
echo                     ^|     _______________________________________________     ^|
echo                     ^|                                                         ^|
echo                     ^|     [6] Go to Main Menu                                 ^|
echo                     ^|                                                         ^|
echo                     ^|_________________________________________________________^|
echo:                                                                               
choice /C:123456 /N /M ">                     Enter Your Choice [1,2,3,4,5,6] : "

if errorlevel 6 goto:MainMenu
if errorlevel 5 goto:ShowIP
if errorlevel 4 goto:DelWindowsIP
if errorlevel 3 goto:DelLinuxIP
if errorlevel 2 goto:AddWindowsIP
if errorlevel 1 goto:AddLinuxIP

:AddLinuxIP
echo:
set input=
set /p input=">                     Enter IP:"
for /f "tokens=1,2,3 delims=." %%a in ("%input%") do (
    set num1=%%a
	set num2=%%b
	set num3=%%c
)
wsl -u root ip addr add %input%/24 broadcast %num1%.%num2%.%num3%.255 dev eth0 label eth0:1
echo:
echo                       Success!
echo:
echo                       Press any key to continue...
pause >nul
goto IPSetting

:AddWindowsIP
echo:
set input=
set /p input=">                     Enter IP:"
netsh interface ip add address "vEthernet (WSL)" %input% 255.255.255.0
echo:
echo                       Success!
echo:
echo                       Press any key to continue...
pause >nul
goto IPSetting

:DelLinuxIP
echo:
set input=
set /p input=">                     Enter IP:"
for /f "tokens=1,2,3 delims=." %%a in ("%input%") do (
    set num1=%%a
	set num2=%%b
	set num3=%%c
)
wsl -u root ip addr del %input%/24 broadcast %num1%.%num2%.%num3%.255 dev eth0 label eth0:1
echo:
echo                       Success!
echo:
echo                       Press any key to continue...
pause >nul
goto IPSetting

:DelWindowsIP
echo:
set input=
set /p input=">                     Enter IP:"
netsh interface ip delete address "vEthernet (WSL)" addr=%input% gateway=all
echo:
echo                       Success!
echo:
echo                       Press any key to continue...
pause >nul
goto IPSetting

:ShowIP
echo:
echo Linux   IP:
bash.exe -c "ip addr show eth0 | grep \"inet\\b\" | awk '{print $2}' | cut -d/ -f1"
echo:
echo Windows IP:
for /f "tokens=2 delims=:" %%b in ('netsh interface ip show config "vEthernet (WSL)"^|find /i "ip"') do (
    for /f "tokens=*" %%i in ("%%b") do echo %%i
)
echo:
echo                       Press any key to continue...
pause >nul
goto IPSetting

::========================================================================================================================================

:Exit

exit /b

::========================================================================================================================================

:ErrExit

echo:
echo Press any key to exit...
pause >nul
exit /b

::========================================================================================================================================

::End::