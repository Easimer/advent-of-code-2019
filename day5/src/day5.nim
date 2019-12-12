import options
import os
import times

import aocutils
import aocutils/intcode

func runProgram(inp: int, memory: Memory): int =
  ## Runs the program and returns the diagnostic code
  var ires: InterpreterResult
  var pc = 0
  var program = memory

  while not ires.halt:
    ires = executeInstruction(inp, pc, program)
    pc = ires.nextPC
    if ires.output.isSome():
      result = ires.output.get()
      #stderr.writeLine("OUT: " & $ires.output.get())

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  
  let parseStart = getTime()
  var program = intcode.readProgramFromPath(inputPath)

  let parseEnd = getTime()

  let part1Start = getTime()
  let output1 = $(runProgram(1, program))
  let part1End = getTime()

  let part2Start = getTime()
  let output2 = $(runProgram(5, program))
  let part2End = getTime()

  var R: AOCResults
  R.init(output1, output2, float inMicroseconds(parseEnd - parseStart), float inMicroseconds(part1End - part1Start), float inMicroseconds(part2End - part2Start))
  printResults(R)