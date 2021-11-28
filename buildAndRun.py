import os
import subprocess
import time

def buildToExe():
    oFiles = [f for f in os.listdir("build") if f.endswith(".o")]
    for file in oFiles:
        os.remove("build/" + file)

    # Compilation
    cFiles = [f for f in os.listdir("src") if f.endswith(".c")]
    cFilesStr = " ".join("../src/{}".format(*cF) for cF in zip(cFiles))

    os.chdir("scripts")
    subprocess.call(['compiler.bat', cFilesStr])

    # Linking
    oFiles = [f for f in os.listdir("../build") if f.endswith(".o")]
    if len(oFiles) is not len(cFiles):
        return False
    
    oFilesStr = " ".join("../build/{}".format(*oF) for oF in zip(oFiles))
    subprocess.call(["linker.bat", oFilesStr])
    os.chdir("..")

    return True

def main():
    start = time.time()
    
    os.system("taskkill /f /im 2KB-PathTracer.exe");
    
    if not os.path.isdir("build"):
        os.mkdir("build")

    if not buildToExe():
        print("Build failed")
        return
    
    print("Build finshed in {}sec".format(round(time.time() - start, 3)))
    print("Note that linking erros are not being catched")

    os.chdir("build")
    os.system("start 2KB-PathTracer.exe")

if __name__ == "__main__":
    main()
