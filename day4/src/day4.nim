import aocutils
import os
import sequtils
import strutils

type ResultCount = int

func passwordOk(pass: int): bool =
  var maxDigit = 10
  var foundDouble = false
  var curPass = pass
  result = true
  while curPass > 0:
    let digit = curPass mod 10
    if digit > maxDigit:
      result = false
    
    if digit == maxDigit:
      foundDouble = true
    maxDigit = digit
    curPass = curPass div 10
  result = result and foundDouble

proc worker(start: int, first: int, last: int): ResultCount =
  result = 0
  echo((first + start, last + start))
  for candidate in first .. last:
    if passwordOk(candidate):
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

  let passRange = readRange()
  echo(passRange)

  let output1 = distributeWork(worker, 0, passRange[0], passRange[1]).foldl(a+b)
  echo(output1)
  
