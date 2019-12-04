import aocutils
import os
import sequtils
import strutils
import times

func passwordOk(pass: int): bool =
  var maxDigit = 10
  var hasDoubleGroup = false
  var dubCounter = 1
  var curPass = pass
  result = true
  while curPass > 0 and result:
    let digit = curPass mod 10
    if digit > maxDigit:
      return false
    
    if digit == maxDigit:
      dubCounter += 1
    else:
      if dubCounter >= 2:
        hasDoubleGroup = true
      dubCounter = 1
    maxDigit = digit
    curPass = curPass div 10
  if dubCounter >= 2:
    hasDoubleGroup = true
  result = result and hasDoubleGroup

func passwordOk2(pass: int): bool =
  var maxDigit = 10
  var hasDoubleGroup = false
  var dubCounter = 1
  var curPass = pass
  result = true
  while curPass > 0 and result:
    let digit = curPass mod 10
    if digit > maxDigit:
      return false
    
    if digit == maxDigit:
      dubCounter += 1
    else:
      if dubCounter == 2:
        hasDoubleGroup = true
      dubCounter = 1
    maxDigit = digit
    curPass = curPass div 10
  if dubCounter == 2:
    hasDoubleGroup = true
  result = result and hasDoubleGroup

proc worker(x: (proc(p: int): bool), first: int, last: int): int =
  for candidate in first .. last:
    if x(candidate): result = result + 1

proc readRange(): (int, int) =
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  var f: File = open(inputPath)
  defer: f.close()

  result = (parseInt(f.readLine()), parseInt(f.readLine()))

when isMainModule:
  let inputStart = getTime()
  let passRange = readRange()
  let inputEnd = getTime()

  let part1Start = getTime()
  let output1 = distributeWork(worker, passwordOk, passRange[0], passRange[1]).foldl(a+b)
  let part1End = getTime()

  let part2Start = getTime()
  let output2 = distributeWork(worker, passwordOk2, passRange[0], passRange[1]).foldl(a+b)
  let part2End = getTime()
  
  var R: AOCResults
  R.init($output1, $output2, float inMicroseconds(inputEnd - inputStart), float inMicroseconds(part1End - part1Start), float inMicroseconds(part2End - part2Start))
  printResults(R)