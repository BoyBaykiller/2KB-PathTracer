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

    result = subprocess.run(['compiler.bat', cFilesStr], capture_output=True, text=True)
    print(result.stdout)
    if result.stderr != "":
        print(result.stderr)
        return False

    # Linking
    oFiles = [f for f in os.listdir("../build") if f.endswith(".o")]
    oFilesStr = " ".join("../build/{}".format(*oF) for oF in zip(oFiles))
    
    result = subprocess.run(["linker.bat", oFilesStr])
    os.chdir("..")

    return True

def main():
    start = time.time()
    
    if not os.path.isdir("build"):
        os.mkdir("build")

    if not buildToExe():
        return
    
    print(f"Build finshed in {round(time.time() - start, 3)}sec")
    print("Note that linking erros are not being catched")

    os.chdir("build")
    os.startfile("2KB-PathTracer")

if __name__ == "__main__":
    main()
