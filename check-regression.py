#!/usr/bin/python3

import json
import subprocess
import os.path as path

def testExe(exePath, exeWD):
    print("=======================================\033[m")
    print("\033[1m" + exePath + "\033[m")
    outputs = []
    ret = True
    with open(exeWD + "/output.txt") as f: outputs = json.loads(f.read())
    try:
        proc = subprocess.run([exePath], cwd = exeWD, capture_output = True)
        J = json.loads(proc.stdout.decode("utf-8"))
        if str(outputs["output1"]) == str(J["output1"]):
            print("Part 1 OK")
        else:
            print(f"Part 1 FAILED: {outputs['output1']} != {J['output1']}")
            ret = False
        if str(outputs["output2"]) == str(J["output2"]):
            print("Part 2 OK")
        else:
            print(f"Part 2 FAILED: {outputs['output2']} != {J['output2']}")
            ret = False
    except Exception as e:
        print("FAILED: " + str(e))
        ret = False
    except JSONDecodeError:
        print("No output")
        ret = False

    return ret

total = 0
ok = 0
fail = 0
for day in range(1, 26):
    pathBase = "day" + str(day)
    workDir = "./" + pathBase + "/"
    exePath = "./" + pathBase + ".exe"
    if path.exists(workDir + exePath):
        total += 1
        if testExe(exePath, workDir):
            ok += 1
        else:
            fail += 1

print(f"Total: {total} OK: {ok} Failed: {fail}")
