@echo off
setlocal enabledelayedexpansion

:: Force script to run in the exact folder where the .bat file lives
cd /d "%~dp0"

:: THE FIX: Force Windows Command Prompt to process ANSI color codes
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: 1. Setup ANSI Colors
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "cGreen=!ESC![92m"
set "cRed=!ESC![91m"
set "cYellow=!ESC![93m"
set "cCyan=!ESC![96m"
set "cReset=!ESC![0m"

:: 2. Create Archive folder
if not exist "Archive" mkdir "Archive"

:: 3. Safely get timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "dt=!dt:~0,14!"
set "logname=Report_!dt:~0,4!-!dt:~4,2!-!dt:~6,2!_!dt:~8,2!!dt:~10,2!!dt:~12,2!.txt"
set "logfile=Archive\!logname!"

set "total=0"
set "pass=0"
set "fail=0"
set "target_file=targets.txt"

if not exist "%target_file%" (
    echo !cRed![ERROR] "%target_file%" not found in: %CD%!cReset!
    pause
    exit /b
)

:: 4. Setup the Log File Header (Hidden from screen, written to text file)
echo ========================================================================================== > "!logfile!"
echo                                      SYSTEM RUN REPORT                                     >> "!logfile!"
echo ========================================================================================== >> "!logfile!"
echo ABOUT THIS SCAN:                                                                           >> "!logfile!"
echo This automated tool reads a list of targets and verifies their status:                     >> "!logfile!"
echo  - WEBSITES: It "knocks" on the web page to ensure it actually loads.                      >> "!logfile!"
echo  - FOLDERS : It tries to access the directory path to ensure it exists.                    >> "!logfile!"
echo  - SERVERS : It sends a network 'ping' (an electronic echo) to confirm                     >> "!logfile!"
echo              the machine is awake, plugged in, and responding.                             >> "!logfile!"
echo  - SAFETY  : Read-only (Ping, Curl, If Exist). Low RAM, zero risk of data deletion.        >> "!logfile!"
echo ========================================================================================== >> "!logfile!"
echo Date : !dt:~0,4!-!dt:~4,2!-!dt:~6,2! Time : !dt:~8,2!:!dt:~10,2!:!dt:~12,2!                 >> "!logfile!"
echo ========================================================================================== >> "!logfile!"
echo STATUS ^| DESCRIPTION                              ^| TARGET (Server / Folder / URL)       >> "!logfile!"
echo ------------------------------------------------------------------------------------------ >> "!logfile!"

:: 5. Start the live scan (Displayed on screen with Cyan headers)
echo !cCyan!==========================================================================================
echo                           Scanning Servers, Folders, and Web URLs...
echo ==========================================================================================
echo HOW IT WORKS:
echo  - Websites : Checking if the page loads properly.
echo  - Folders  : Verifying the directory can be accessed.
echo  - Servers  : Pinging the machine to see if it is awake.
echo  - Safety   : Read-only (Ping, Curl, If Exist). Low RAM, zero risk of data deletion.
echo ==========================================================================================!cReset!
echo.

:: Read the target file, splitting by comma
for /f "usebackq tokens=1,* delims=," %%A in ("%target_file%") do (
    set "target=%%A"
    set "desc=%%B"
    set /a total+=1
    
    if not "!desc!"=="" (
        for /f "tokens=* delims= " %%C in ("!desc!") do set "desc=%%C"
        set "desc=[!desc!]"
    ) else (
        set "desc=[-]"
    )
    
    :: STRING PADDING
    set "desc_pad=!desc!                                        "
    set "desc_pad=!desc_pad:~0,40!"
    set "display_text=!desc_pad! ^| !target!"
    
    echo !target! | findstr /b /i "http" >nul
    if !errorlevel! equ 0 (
        curl -o nul -s -f -m 2 "!target!"
        if !errorlevel! equ 0 (
            echo !cGreen![OK]!cReset!   ^| !display_text!
            echo [OK]   ^| !display_text!>> "!logfile!"
            set /a pass+=1
        ) else (
            echo !cRed![FAIL]!cReset! ^| !display_text!
            echo [FAIL] ^| !display_text!>> "!logfile!"
            set /a fail+=1
        )
    ) else (
        echo !target! | find "\" >nul
        if !errorlevel! equ 0 (
            if exist "!target!\" (
                echo !cGreen![OK]!cReset!   ^| !display_text!
                echo [OK]   ^| !display_text!>> "!logfile!"
                set /a pass+=1
            ) else (
                echo !cRed![FAIL]!cReset! ^| !display_text!
                echo [FAIL] ^| !display_text!>> "!logfile!"
                set /a fail+=1
            )
        ) else (
            ping -n 1 -w 1000 !target! >nul
            if !errorlevel! equ 0 (
                echo !cGreen![OK]!cReset!   ^| !display_text!
                echo [OK]   ^| !display_text!>> "!logfile!"
                set /a pass+=1
            ) else (
                echo !cRed![FAIL]!cReset! ^| !display_text!
                echo [FAIL] ^| !display_text!>> "!logfile!"
                set /a fail+=1
            )
        )
    )
)

:: 6. Calculate Percentage and Determine System Message
set "sys_msg2="
set "sys_msg3="
set "sum_color=!cYellow!"

if !total! equ 0 (
    set "pct=0"
    set "sum_color=!cRed!"
    set "sys_msg1=GHOST TOWN. No targets were found to check."
    set "sys_msg2=Did you delete the list?"
    goto :PrintReport
)

set /a pct=(!pass! * 100) / !total!

:: Assign Summary Color Based on Percentage
if !pct! equ 100 set "sum_color=!cGreen!"
if !pct! lss 100 if !pct! geq 40 set "sum_color=!cYellow!"
if !pct! lss 40 set "sum_color=!cRed!"

if !pct! equ 100 set "sys_msg1=FLAWLESS VICTORY. The network gods are smiling upon you." & set "sys_msg2=Everything is online, operational, and running perfectly." & set "sys_msg3=Go grab a coffee. Your excuse for not working is officially denied."
if !pct! lss 100 if !pct! geq 80 set "sys_msg1=MINOR TURBULENCE. Most systems are green, but a few are" & set "sys_msg2=taking an unscheduled nap. Nothing you can't handle," & set "sys_msg3=but definitely worth a quick investigation."
if !pct! lss 80 if !pct! geq 60 set "sys_msg1=CAUTION REQUIRED. We are entering sketchy territory. Enough" & set "sys_msg2=systems are down that people will start noticing soon." & set "sys_msg3=Time to put on the troubleshooting hat."
if !pct! lss 60 if !pct! geq 40 set "sys_msg1=CRITICAL WARNING. We are operating on life support." & set "sys_msg2=The network is currently held together by duct tape." & set "sys_msg3=Sound the alarm."
if !pct! lss 40 if !pct! geq 20 set "sys_msg1=SYSTEM MELTDOWN. Wow. Just... wow. It is a digital wasteland" & set "sys_msg2=out there. Are the servers even plugged in?" & set "sys_msg3=Grab a fire extinguisher."
if !pct! lss 20 set "sys_msg1=CATASTROPHIC FAILURE. The network has left the chat." & set "sys_msg2=There is no point in even trying to work right now." & set "sys_msg3=Pack your bags, go home, try again tomorrow."

:PrintReport
:: 7. Finish the Log File (Raw Text)
echo ------------------------------------------------------------------------------------------ >> "!logfile!"
echo SUMMARY: Total Checked: !total!  ^|  Success: !pass!  ^|  Failed: !fail!                 >> "!logfile!"
echo HEALTH : !pct!%% >> "!logfile!"
echo SYSTEM : !sys_msg1! >> "!logfile!"
if not "!sys_msg2!"=="" echo          !sys_msg2! >> "!logfile!"
if not "!sys_msg3!"=="" echo          !sys_msg3! >> "!logfile!"
echo ========================================================================================== >> "!logfile!"

:: 8. Display Final Summary on Screen (Colored Text)
echo.
echo !sum_color!==========================================================================================
echo SUMMARY: Total Checked: !total!  ^|  Success: !pass!  ^|  Failed: !fail!
echo HEALTH : !pct!%%
echo SYSTEM : !sys_msg1!
if not "!sys_msg2!"=="" echo          !sys_msg2!
if not "!sys_msg3!"=="" echo          !sys_msg3!
echo ==========================================================================================!cReset!
echo.
echo !cCyan!Log successfully saved to the Archive folder as: !logname!!cReset!
pause
