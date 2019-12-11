import aocutils/intcode
import os
import tables
import options
import json
import gifwriter

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


const ANIM_SCALE = 8

func createPixelBuffer(width, height: int): seq[Color] = newSeq[Color](ANIM_SCALE * ANIM_SCALE * width * height)

proc setPixel(buffer: var seq[Color], x, y: int, w, h: int, c: Color) =
  for yoff in 0 .. ANIM_SCALE - 1:
    let rowOffset = (y * ANIM_SCALE + yoff) * ANIM_SCALE * w
    for xoff in 0 .. ANIM_SCALE - 1:
      buffer[rowOffset + ANIM_SCALE * x + xoff] = c
    
proc run(origProgram: seq[int], startOn = Black): (int, string) =
  var state: InterpreterResult
  var program = origProgram

  var map: Table[(int, int), Tile]
  var pos: (int, int) = (0, 0)
  var dir = 1 # Up
  var mode = Paint # Paint mode
  map[pos] = startOn

  let width = 64
  let height = 16
  var anim = newGif("11.gif", ANIM_SCALE * width, ANIM_SCALE * height, colors = 16)
  defer: close(anim)
  var pixels = createPixelBuffer(width, height)

  while not state.halt:
    let input = if getTile(pos, map) == White: 1 else: 0
    state = executeInstruction(input, state.nextPC, program, state.base)
    if state.output.isSome():
      case mode:
        of Paint:
          case state.output.get():
            of 0:
              map[pos] = Black
              if pos[0] >= 0 and pos[0] <= 40 and pos[1] >= -5 and pos[1] <= 5:
                setPixel(pixels, pos[0], pos[1] + 5, width, height, Color(r: 0, g: 0, b: 0))
              anim.write(pixels)
            of 1:
              map[pos] = White
              if pos[0] >= 0 and pos[0] <= 40 and pos[1] >= -5 and pos[1] <= 5:
                setPixel(pixels, pos[0], pos[1] + 5, width, height, Color(r: 255, g: 255, b: 255))
              anim.write(pixels)
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
          if pos[0] >= 0 and pos[0] <= 40 and pos[1] >= -5 and pos[1] <= 5:
            setPixel(pixels, pos[0], pos[1] + 5, width, height, Color(r: 255, g: 0, b: 0))
          anim.write(pixels)
  
  for k, v in map:
    result[0] += 1

  for y in -5 .. 5:
    for x in 0 .. 40:
      if (x, y) in map:
          result[1] &= (if map[(x, y)] == White: '#' else: '.')
          setPixel(pixels, x, y + 5, width, height, if map[(x, y)] == White: Color(r: 255, g: 255, b: 255) else: Color(r: 0, g: 0, b: 0))
      else:
        result[1] &= "."
        setPixel(pixels, x, y + 5, width, height, Color(r: 0, g: 0, b: 0))
    result[1] &= '\n'
  anim.write(pixels, delay = 2.0)

when isMainModule:
  let inputPath = if paramCount() > 0: paramStr(1) else: "input.txt"
  var program = readProgramFromPath(inputPath)
  let output1 = run(program, Black)[0]
  let output2 = run(program, White)[1]
  echo(%*{"output1": output1, "output2": output2})
  stderr.write(output2)