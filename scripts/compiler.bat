@echo off

echo ****************** HELLO FROM %~n0%~x0 ******************

SET CSourceFiles=%~1

if "%CSourceFiles%" == "" ( 
    echo Error! No .c files were passed 
    exit
)

cd ../build

:: /std:c17 language version
:: /c      produce .obj files instead of .exe
:: /Os      optimize for size
:: /Od      disable performance optimizations
:: /GS-     ommit security stuff
set CMD=../scripts/clEnv.bat /c /std:c17 /Os /O2 /GS- /UNSAFEIMPORT %CSourceFiles%
::set CMD=C:\MinGW\bin\gcc.exe -c -m32 -std=c11 -nostdlib -Os -fno-exceptions -fomit-frame-pointer %CSourceFiles%
echo %CMD%
%CMD%

echo ****************** %~n0%~x0 SAY's BYE ******************
echo.
