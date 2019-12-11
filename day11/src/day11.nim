import aocutils/intcode
import os
import tables
import options
import json

type
  Tile = enum
    Black, White
  RobotMode = enum
    Paint, Turn

func getTile(pos: (int, int), map: Table[(int, int), Tile]): Tile =
  if pos in map:
    map[pos]
  else:
    Black

proc run(origProgram: Memory, startOn = Black): (int, string) =
  var state: InterpreterResult
  var program = origProgram

  var map: Table[(int, int), Tile]
  var pos: (int, int) = (0, 0)
  var dir = 1 # Up
  var mode = Paint # Paint mode
  map[pos] = startOn

  while not state.halt:
    let input = if getTile(pos, map) == White: 1 else: 0
    state = executeInstruction(input, state.nextPC, program, state.base)
    if state.output.isSome():
      case mode:
        of Paint:
          case state.output.get():
            of 0:
              map[pos] = Black
            of 1:
              map[pos] = White
            else: raise newException(ValueError, "FUG")
          mode = Turn
        of Turn:
          case state.output.get():
            of 0:
              dir = (dir + 1)
              if dir > 3: dir -= 4
            of 1:
              dir = (dir - 1) mod 4
              if dir < 0: dir += 4
            else: raise newException(ValueError, "FUG")
          case dir:
            of 0: pos[0] += 1
            of 1: pos[1] += 1
            of 2: pos[0] -= 1
            of 3: pos[1] -= 1
            else: raise newException(ValueError, "FUG")
          mode = Paint
  
  for k, v in map:
    result[0] += 1

  for y in -5 .. 5:
    for x in 0 .. 40:
      if (x, y) in map:
          result[1] &= (if map[(x, y)] == White: '#' else: '.')
      else:
        result[1] &= "."
    result[1] &= '\n'

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  var program = readProgramFromPath(inputPath)
  let output1 = run(program, Black)[0]
  let output2 = run(program, White)[1]
  echo(%*{"output1": output1, "output2": output2})
  stderr.write(output2)