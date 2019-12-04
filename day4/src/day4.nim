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

type
  WorkKind = enum
    Range, Seq
  Day4Work = object
    f: (proc(p: int): bool)
    case kind: WorkKind
      of Range:
        _: int
      of Seq:
        S: seq[int]

proc worker(work: Day4Work, first: int, last: int): seq[int] =
  case work.kind:
    of Range:
      for candidate in first .. last:
        if passwordOk(candidate): result.add(candidate)
    of Seq:
      for i in first .. last:
        if passwordOk2(work.S[i]): result.add(work.S[i])

proc readRange(): (int, int) =
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  var f: File = open(inputPath)
  defer: f.close()
  result = (parseInt(f.readLine()), parseInt(f.readLine()))

when isMainModule:
  let inputStart = getTime()
  let passRange = readRange()
  let inputEnd = getTime()

  var W1: Day4Work
  W1.kind = WorkKind.Range
  let part1Start = getTime()
  let validPasswords = distributeWork(worker, W1, passRange[0], passRange[1]).foldl(a & b)
  let output1 = len(validPasswords)
  let part1End = getTime()

  var W2: Day4Work
  W2.kind = WorkKind.Seq
  W2.S = validPasswords
  let part2Start = getTime()
  let output2 = len(distributeWork(worker, W2, 0, validPasswords.high()).foldl(a & b))
  let part2End = getTime()
  
  var R: AOCResults
  R.init($output1, $output2, float inMicroseconds(inputEnd - inputStart), float inMicroseconds(part1End - part1Start), float inMicroseconds(part2End - part2Start))
  printResults(R)