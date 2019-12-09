import aocutils/intcode
import os
import options

func runWithInput(input: int, origProgram: seq[int]): int =
  var state: InterpreterResult
  var program = origProgram

  while not state.halt:
    state = executeInstruction(input, state.nextPC, program, state.base)
    if state.output.isSome():
      return state.output.get()

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"

  var program = readProgramFromPath(inputPath)
  echo(runWithInput(1, program))
  echo(runWithInput(2, program))

  
