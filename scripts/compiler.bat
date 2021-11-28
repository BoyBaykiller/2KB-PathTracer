@echo off

echo ****************** HELLO FROM %~n0%~x0 ******************

SET CSourceFiles=%~1

if "%CSourceFiles%" == "" ( 
    echo Error! No source files were passed 
    exit
)

cd ../build

set CMD=gcc -Wall -c -m32 -std=c11 -O2 -Os -fno-exceptions -fomit-frame-pointer -fno-inline-small-functions %CSourceFiles%

echo %CMD%
%CMD%

echo ****************** %~n0%~x0 SAY's BYE ******************
echo.
