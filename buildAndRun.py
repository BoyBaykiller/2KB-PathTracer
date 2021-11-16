import os
from os import listdir
import subprocess
import time

def buildToExe():
    oFiles = [f for f in listdir("build") if os.path.splitext(f)[1] == ".obj"]
    for file in oFiles:
        os.remove("build/" + file)

    # Compilation
    cFiles = [f for f in listdir("src") if os.path.splitext(f)[1] == ".c"]
    cFilesStr = ""
    for file in cFiles:
        cFilesStr += "../src/{} ".format(file)


    os.chdir("scripts")
    subprocess.call(['compiler.bat', cFilesStr])

    # Linking
    oFiles = [f for f in listdir("../build") if os.path.splitext(f)[1] == ".obj"]
    if oFiles.__len__() is not cFiles.__len__():
        print("Build failed. Compilation error in {}/{} files".format(cFiles.__len__() - oFiles.__len__(), cFiles.__len__()))
        return False

    oFilesStr = ""
    for file in oFiles:
        oFilesStr += "../build/{} ".format(file)

    subprocess.call(["linker.bat", oFilesStr])
    os.chdir("..")

    return True

def main():
    start = time.time()
    
    os.system("taskkill /f /im 2KB-PathTracer.exe");
    
    if not os.path.isdir("build"):
        os.mkdir("build")

    if not buildToExe():
        return
    
    print("Build in {}sec".format(round(time.time() - start, 3)))
    print("Note that linking erros are not being catched")
    os.chdir("build")
    os.system("start 2KB-PathTracer.exe")

if __name__ == "__main__":
    main()
