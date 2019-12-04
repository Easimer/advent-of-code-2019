import aocutils
import os
import sequtils
import strutils
import times

type ResultCount = int

func passwordOk(pass: int): bool =
  var maxDigit = 10
  var hasDoubleGroup = false
  var dubCounter = 1
  var curPass = pass
  result = true
  while curPass > 0 and result:
    let digit = curPass mod 10
    if digit > maxDigit:
      result = false
    
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
      result = false
    
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

proc worker(x: int, first: int, last: int): ResultCount =
  result = 0
  for candidate in first .. last:
    if passwordOk(candidate):
      result = result + 1

proc worker2(x: int, first: int, last: int): ResultCount =
  result = 0
  for candidate in first .. last:
    if passwordOk2(candidate):
      result = result + 1

proc readRange(): (int, int) =
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  var f: File = open(inputPath)
  defer: f.close()

  result = (parseInt(f.readLine()), parseInt(f.readLine()))

when isMainModule:
  assert(passwordOk(111111))
  assert(not passwordOk(223450)) # decreasing
  assert(not passwordOk(123789)) # no double
  assert(passwordOk(123345))
  assert(passwordOk(123445))
  assert(passwordOk(888899))

  assert(passwordOk2(112233))
  assert(not passwordOk2(123444))
  assert(passwordOk2(111122))
  assert(passwordOk2(123445))
  assert(passwordOk2(112344))
  assert(passwordOk2(112345))
  assert(not passwordOk2(123789))
  assert(not passwordOk2(223450))

  let inputStart = getTime()
  let passRange = readRange()
  let inputEnd = getTime()

  let part1Start = getTime()
  let output1 = distributeWork(worker, 0, passRange[0], passRange[1]).foldl(a+b)
  let part1End = getTime()

  let part2Start = getTime()
  let output2 = distributeWork(worker2, 0, passRange[0], passRange[1]).foldl(a+b)
  let part2End = getTime()
  
  var R: AOCResults
  R.init($output1, $output2, float inMicroseconds(inputEnd - inputStart), float inMicroseconds(part1End - part1Start), float inMicroseconds(part2End - part2Start))
  printResults(R)