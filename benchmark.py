#!/usr/bin/python3

import json
import subprocess
import os.path as path
from statistics import mean, stdev

def printStats(label, data, unit):
        print("{} \033[31mmean \033[m{} {}\t\033[32mstdev \033[m{} {}".format(label,
            round(mean(data), 4), unit,
            round(stdev(data), 4), unit))

def benchmarkExe(exePath, exeWD):
    timePreprocess = []
    timePart1 = []
    timePart2 = []
    unitTime = "s"
    timeCombined = False
    sampleCount = 512

    print("=======================================\033[m")
    print("\033[1m" + exePath + "\033[m")
    try:
        for i in range(sampleCount):
            proc = subprocess.run([exePath], capture_output = True, cwd = exeWD)
            J = json.loads(proc.stdout.decode("utf-8"))
            timePreprocess.append(J["timePreprocess"])
            timePart1.append(J["timePart1"])
            timePart2.append(J["timePart2"])
            if "unitTime" in J:
                unitTime = J["unitTime"]
            if "isTimeCombined" in J:
                timeCombined = J["isTimeCombined"]

        print("Sample count: {}".format(sampleCount))
        printStats("Preprocess:", timePreprocess, unitTime)
        if timeCombined:
            printStats("Part 1 & 2:", timePart1, unitTime)
        else:
            printStats("Part 1:    ", timePart1, unitTime)
            printStats("Part 2:    ", timePart2, unitTime)
    except Exception as e:
        print("FAILED: " + str(e))


for day in range(1, 26):
    pathBase = "day" + str(day)
    workDir = "./" + pathBase + "/"
    exePath = "./" + pathBase + ".exe"
    if path.exists(workDir + exePath):
        benchmarkExe(exePath, workDir)

