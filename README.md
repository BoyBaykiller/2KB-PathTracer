# 2KB-PathTracer
This project is just me trying to get as much of a "Path Tracer" into a 2KB executable. I am taking the Path Tracing shader from [an other project](https://github.com/JulianStambuk/OpenTK-PathTracer) so it's more a task of learning C, building a development evironment and copy pasting Win32 API Code. Note that I am deliberately doing things like not calling `free` because of size.

# Build
This project uses **Microsoft's MSVC** as a Compiler (cl.exe) and **[Crinkler](https://github.com/runestubbe/Crinkler)** for linking. You also need to have **Win 10 SDK in version 10.0.19041.0** installed.
Crinkler is included in this project and the other come with a basic installation of Visual Studio.

Navigate to the root directory, open a terminal and run `py .\buildAndRun.py`.
This build the project into a build folder and starts the EXE.