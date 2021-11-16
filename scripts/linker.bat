@echo off

echo ****************** HELLO FROM %~n0%~x0 ******************

SET OSourceFiles=%~1

if "%OSourceFiles%" == "" ( 
    echo Error! No .o files were passed 
    exit
)

cd ../build

set LibPath="C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x86\"
:: /NODEFAULTLIB 
set CMD=../Crinkler.exe /OUT:2KB-PathTracer.exe /entry:WinMain /SUBSYSTEM:console /LIBPATH:%LibPath% %OSourceFiles% kernel32.lib user32.lib gdi32.lib opengl32.lib winmm.lib
echo %CMD%
start /W %CMD%

echo ****************** %~n0%~x0 SAY's BYE ******************
echo.
