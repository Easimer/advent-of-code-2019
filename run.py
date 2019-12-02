#!/usr/bin/python3

import json
import subprocess
import os.path as path
import sys

def benchmarkExe(exePath, exeWD, args):
    timePreprocess = 0
    timePart1 = 0
    timePart2 = 0
    unitTime = "s"
    timeCombined = False

    print("=======================================\033[m")
    print("\033[1m" + exePath + "\033[m")
    try:
        proc = subprocess.run([exePath] + args, capture_output = True, cwd = exeWD)
        J = json.loads(proc.stdout.decode("utf-8"))
        timePreprocess = (J["timePreprocess"])
        timePart1 = (J["timePart1"])
        timePart2 = (J["timePart2"])
        if "unitTime" in J:
            unitTime = J["unitTime"]
        if "isTimeCombined" in J:
            timeCombined = J["isTimeCombined"]

        print(f"Preprocess: {timePreprocess} {unitTime}")
        if timeCombined:
            printStats("Part 1 & 2:", timePart1, unitTime)
            print(f"Part 1 & 2: {timePart1}")
        else:
            print(f"Part 1:     {timePart1} {unitTime}")
            print(f"Part 2:     {timePart2} {unitTime}")
    except Exception as e:
        print("FAILED: " + str(e))

if len(sys.argv) > 1:
    day = sys.argv[1]
    pathBase = "day" + str(day)
    workDir = "./" + pathBase + "/"
    exePath = "./" + pathBase + ".exe"
    benchmarkExe(exePath, workDir, sys.argv[2:])
